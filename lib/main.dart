import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/divination_repository_impl.dart';
import 'data/secure/secure_storage.dart';
import 'domain/repositories/divination_repository.dart';
import 'domain/divination_registry.dart';
import 'domain/divination_system.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/home/method_selector_screen.dart';
import 'presentation/screens/history/history_list_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/ai_settings_screen.dart';
import 'divination_systems/liuyao/liuyao_system.dart';
import 'divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart';
import 'divination_systems/registry_bootstrap.dart';
import 'ai/ai_bootstrap.dart';
import 'ai/service/ai_analysis_service.dart';

/// 万象排盘应用入口（新架构）
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 注册所有术数系统和 UI 工厂
  DivinationSystemBootstrap.registerAll();

  // 验证注册（开发模式）
  if (kDebugMode) {
    final isValid = DivinationSystemBootstrap.verifyRegistration();
    if (!isValid) {
      throw StateError('System registration failed');
    }
    DivinationSystemBootstrap.printRegistrationInfo();
  }

  runApp(const WanxiangPaipanApp());
}

/// 应用根组件
class WanxiangPaipanApp extends StatefulWidget {
  /// 构造函数
  const WanxiangPaipanApp({super.key});

  @override
  State<WanxiangPaipanApp> createState() => _WanxiangPaipanAppState();
}

class _WanxiangPaipanAppState extends State<WanxiangPaipanApp> {
  late final AppDatabase _database;
  late final SecureStorage _secureStorage;
  AIAnalysisService? _aiService;
  bool _aiInitialized = false;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _secureStorage = SecureStorage();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      final service = await AIBootstrap.initialize(
        database: _database,
        secureStorage: _secureStorage,
      );
      if (mounted) {
        setState(() {
          _aiService = service;
          _aiInitialized = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI initialization failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ==================== 数据层依赖 ====================
        Provider<AppDatabase>.value(value: _database),
        Provider<SecureStorage>.value(value: _secureStorage),

        // ==================== 注册表 ====================
        Provider<DivinationRegistry>(
          create: (_) => DivinationRegistry(),
        ),

        // ==================== Repository 层 ====================
        ProxyProvider2<AppDatabase, SecureStorage, DivinationRepository>(
          update: (context, db, storage, previous) =>
              previous ??
              DivinationRepositoryImpl(
                database: db,
                secureStorage: storage,
                registry: context.read<DivinationRegistry>(),
              ),
        ),

        // ==================== AI 服务 ====================
        if (_aiService != null)
          ChangeNotifierProvider<AIAnalysisService>.value(
            value: _aiService!,
          ),

        // ==================== 六爻系统 ====================
        Provider<LiuYaoSystem>(
          create: (_) => LiuYaoSystem(),
        ),

        // 六爻 ViewModel
        ChangeNotifierProxyProvider2<LiuYaoSystem, DivinationRepository,
            LiuYaoViewModel>(
          create: (context) => LiuYaoViewModel(
            system: context.read<LiuYaoSystem>(),
            repository: context.read<DivinationRepository>(),
          ),
          update: (_, system, repository, previousViewModel) =>
              previousViewModel ??
              LiuYaoViewModel(
                system: system,
                repository: repository,
              ),
        ),
      ],
      child: MaterialApp(
        title: '万象排盘',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const HomeScreen(),
        routes: {
          '/method-selector': (context) {
            final systemType = ModalRoute.of(context)!.settings.arguments
                as DivinationType;
            return MethodSelectorScreen(systemType: systemType);
          },
          '/history': (context) => const HistoryListScreen(),
          '/settings': (context) => const SettingsScreen()
        },
      ),
    );
  }
}


