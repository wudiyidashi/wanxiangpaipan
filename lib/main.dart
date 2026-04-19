import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/navigation/route_observer.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/divination_repository_impl.dart';
import 'data/secure/secure_storage.dart';
import 'domain/repositories/divination_repository.dart';
import 'domain/divination_registry.dart';
import 'domain/services/data_management_service.dart';
import 'domain/services/last_cast_method_service.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/history/history_list_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/ai_settings_screen.dart';
import 'presentation/screens/settings/data_management_screen.dart';
import 'presentation/screens/settings/prompt_template_settings_screen.dart';
import 'divination_systems/liuyao/liuyao_system.dart';
import 'divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart';
import 'divination_systems/meihua/meihua_system.dart';
import 'divination_systems/meihua/viewmodels/meihua_viewmodel.dart';
import 'divination_systems/xiaoliuren/xiaoliuren_system.dart';
import 'divination_systems/xiaoliuren/viewmodels/xiaoliuren_viewmodel.dart';
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

        // ==================== 跨系统记忆服务 ====================
        ProxyProvider<DivinationRepository, LastCastMethodService>(
          update: (_, repository, previous) =>
              previous ?? LastCastMethodService(repository: repository),
        ),

        ProxyProvider<DivinationRepository, DataManagementService>(
          update: (_, repository, previous) => DataManagementService(
            repository: repository,
            aiConfigManager:
                AIBootstrap.isInitialized ? AIBootstrap.configManager : null,
            aiAnalysisService: _aiService,
            registry: DivinationRegistry(),
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

        Provider<MeiHuaSystem>(
          create: (_) => MeiHuaSystem(),
        ),

        ChangeNotifierProxyProvider2<MeiHuaSystem, DivinationRepository,
            MeiHuaViewModel>(
          create: (context) => MeiHuaViewModel(
            system: context.read<MeiHuaSystem>(),
            repository: context.read<DivinationRepository>(),
          ),
          update: (_, system, repository, previousViewModel) =>
              previousViewModel ??
              MeiHuaViewModel(
                system: system,
                repository: repository,
              ),
        ),

        Provider<XiaoLiuRenSystem>(
          create: (_) => XiaoLiuRenSystem(),
        ),

        ChangeNotifierProxyProvider2<XiaoLiuRenSystem, DivinationRepository,
            XiaoLiuRenViewModel>(
          create: (context) => XiaoLiuRenViewModel(
            system: context.read<XiaoLiuRenSystem>(),
            repository: context.read<DivinationRepository>(),
          ),
          update: (_, system, repository, previousViewModel) =>
              previousViewModel ??
              XiaoLiuRenViewModel(
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
        navigatorObservers: [appRouteObserver],
        home: const HomeScreen(),
        routes: {
          '/history': (context) => const HistoryListScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/ai-settings': (context) => const AISettingsScreen(),
          '/data-management': (context) => const DataManagementScreen(),
          '/prompt-template-settings': (context) =>
              const PromptTemplateSettingsScreen(),
        },
      ),
    );
  }
}
