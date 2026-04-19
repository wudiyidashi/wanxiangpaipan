import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../domain/services/last_cast_method_service.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/ai_analysis_widget.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../../../presentation/widgets/history_record_card.dart';
import '../meihua_system.dart';
import '../models/meihua_result.dart';
import 'meihua_hexagram_diagram.dart';

/// 梅花易数 UI 工厂
///
/// 实现 DivinationUIFactory：一个统一起卦界面（时间 / 数字 / 手动三模式下拉切换），
/// 一个按 `docs/architecture/divination-systems/meihua.md §9` 铺排的结果页。
class MeiHuaUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.meiHua;

  @override
  Widget buildCastScreen(CastMethod method) => const _MeiHuaCastScreen();

  @override
  Widget buildResultScreen(DivinationResult result) {
    if (result is! MeiHuaResult) {
      throw ArgumentError(
        '结果类型必须是 MeiHuaResult，实际类型: ${result.runtimeType}',
      );
    }
    return _MeiHuaResultScreen(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) =>
      HistoryRecordCard(result: result);

  @override
  IconData? getSystemIcon() => Icons.local_florist;

  @override
  Color? getSystemColor() => AppColors.meihuaColor;
}

// ============================================================
// 统一起卦界面
// ============================================================

class _MeiHuaCastScreen extends StatefulWidget {
  const _MeiHuaCastScreen();

  @override
  State<_MeiHuaCastScreen> createState() => _MeiHuaCastScreenState();
}

class _MeiHuaCastScreenState extends State<_MeiHuaCastScreen> {
  static const List<CastMethod> _availableMethods = [
    CastMethod.time,
    CastMethod.number,
    CastMethod.manual,
  ];

  static const Map<CastMethod, String> _methodLabels = {
    CastMethod.time: '时间起卦',
    CastMethod.number: '数字起卦',
    CastMethod.manual: '手动输入',
  };

  static const List<String> _trigramNames = [
    '乾',
    '兑',
    '离',
    '震',
    '巽',
    '坎',
    '艮',
    '坤',
  ];

  static const Map<int, String> _movingLineLabels = {
    1: '初爻',
    2: '二爻',
    3: '三爻',
    4: '四爻',
    5: '五爻',
    6: '上爻',
  };

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _upperNumberController = TextEditingController();
  final TextEditingController _lowerNumberController = TextEditingController();

  CastMethod _selectedMethod = CastMethod.time;
  String _manualUpperTrigram = '乾';
  String _manualLowerTrigram = '坤';
  int _manualMovingLine = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastMethod();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _upperNumberController.dispose();
    _lowerNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadLastMethod() async {
    final LastCastMethodService service;
    try {
      service = context.read<LastCastMethodService>();
    } catch (_) {
      return;
    }
    final method = await service.getLastMethod(
      DivinationType.meiHua,
      allowed: _availableMethods,
    );
    if (method != null && mounted) {
      setState(() => _selectedMethod = method);
    }
  }

  Future<void> _handleCast() async {
    if (_isLoading) return;

    Map<String, dynamic>? input;
    switch (_selectedMethod) {
      case CastMethod.time:
        input = const {};
      case CastMethod.number:
        final upper = int.tryParse(_upperNumberController.text.trim());
        final lower = int.tryParse(_lowerNumberController.text.trim());
        if (upper == null || upper <= 0) {
          _showError('请输入有效的上卦数字');
          return;
        }
        if (lower == null || lower <= 0) {
          _showError('请输入有效的下卦数字');
          return;
        }
        input = {'upperNumber': upper, 'lowerNumber': lower};
      case CastMethod.manual:
        input = {
          'upperTrigram': _manualUpperTrigram,
          'lowerTrigram': _manualLowerTrigram,
          'movingLine': _manualMovingLine,
        };
      default:
        _showError('梅花不支持该起卦方式');
        return;
    }

    setState(() => _isLoading = true);
    try {
      final system = MeiHuaSystem();
      final result = await system.cast(
        method: _selectedMethod,
        input: input,
        castTime: DateTime.now(),
      );

      if (!mounted) return;

      try {
        final repository = context.read<DivinationRepository>();
        await repository.saveRecord(result);
        final question = _questionController.text.trim();
        if (question.isNotEmpty) {
          await repository.saveEncryptedFieldsBatch({
            'question_${result.id}': question,
          });
        }
      } catch (saveError) {
        debugPrint('MeiHua: failed to save record: $saveError');
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _MeiHuaResultScreen(result: result as MeiHuaResult),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('起卦失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorDeep,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AntiqueScaffold(
      showCompass: true,
      appBar: const AntiqueAppBar(title: '梅花易数起卦'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionSection(),
              const SizedBox(height: 16),
              _buildMethodSelector(),
              const SizedBox(height: 16),
              const AntiqueDivider(),
              const SizedBox(height: 20),
              _buildMethodBody(),
              const SizedBox(height: 24),
              AntiqueButton(
                label: _isLoading ? '起卦中...' : '起卦',
                onPressed: _isLoading ? null : _handleCast,
                variant: AntiqueButtonVariant.primary,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('占问事项', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueTextField(
          controller: _questionController,
          hint: '请输入您想占问的事项...',
          maxLines: 2,
          minLines: 1,
        ),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('起卦方式', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<CastMethod>(
          value: _selectedMethod,
          items: _availableMethods
              .map(
                (m) => AntiqueDropdownItem<CastMethod>(
                  value: m,
                  label: _methodLabels[m] ?? m.displayName,
                ),
              )
              .toList(),
          onChanged: (m) {
            if (m != null) setState(() => _selectedMethod = m);
          },
        ),
      ],
    );
  }

  Widget _buildMethodBody() {
    switch (_selectedMethod) {
      case CastMethod.time:
        return _buildTimeBody();
      case CastMethod.number:
        return _buildNumberBody();
      case CastMethod.manual:
        return _buildManualBody();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimeBody() {
    final now = DateTime.now();
    final lunar = Lunar.fromDate(now);
    final ganZhi = '${lunar.getYearInGanZhi()}年 '
        '${lunar.getMonthInGanZhi()}月 '
        '${lunar.getDayInGanZhi()}日 '
        '${lunar.getTimeInGanZhi()}时';
    final lunarText =
        '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()} ${lunar.getTimeZhi()}时';

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '当前时辰'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Text(
            ganZhi,
            style: AppTextStyles.antiqueTitle.copyWith(
              fontSize: 15,
              color: AppColors.meihuaColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lunarText,
            style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
          ),
          const SizedBox(height: 6),
          Text(
            '取农历年支数、月数、日数、时支数推上下卦与动爻',
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberBody() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '报两个数'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: '上卦数',
                  controller: _upperNumberController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  label: '下卦数',
                  controller: _lowerNumberController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '上数取上卦，下数取下卦，两数之和取动爻',
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: AppColors.danjin),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.antiqueBody,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '请输入正整数',
              hintStyle: AppTextStyles.antiqueBody.copyWith(
                color: AppColors.qianhe,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualBody() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '指定卦与动爻'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTrigramDropdown(
                  label: '上卦',
                  value: _manualUpperTrigram,
                  onChanged: (v) {
                    if (v != null) setState(() => _manualUpperTrigram = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrigramDropdown(
                  label: '下卦',
                  value: _manualLowerTrigram,
                  onChanged: (v) {
                    if (v != null) setState(() => _manualLowerTrigram = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMovingLineDropdown(),
          const SizedBox(height: 8),
          Text(
            '动爻决定体用：动爻在 1–3 爻则上为体下为用；在 4–6 爻则反之',
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTrigramDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        AntiqueDropdown<String>(
          value: value,
          items: _trigramNames
              .map((n) => AntiqueDropdownItem<String>(value: n, label: n))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMovingLineDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('动爻', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        AntiqueDropdown<int>(
          value: _manualMovingLine,
          items: _movingLineLabels.entries
              .map(
                (e) => AntiqueDropdownItem<int>(
                  value: e.key,
                  label: e.value,
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _manualMovingLine = v);
          },
        ),
      ],
    );
  }
}

// ============================================================
// 结果页
// ============================================================

class _MeiHuaResultScreen extends StatelessWidget {
  final MeiHuaResult result;

  const _MeiHuaResultScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    final questionFuture = _loadQuestion(context);

    return FutureBuilder<String?>(
      future: questionFuture,
      builder: (context, snapshot) {
        final question = (snapshot.data ?? '').trim();
        return AntiqueScaffold(
          appBar: const AntiqueAppBar(title: '梅花易数排盘结果'),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExtendedInfoSection(
                    castTime: result.castTime,
                    lunarInfo: result.lunarInfo,
                    liuShen: const [],
                  ),
                  _buildQuestionSection(question),
                  const SizedBox(height: 12),
                  _buildOverviewSection(),
                  const SizedBox(height: 12),
                  _buildSourceSection(),
                  const SizedBox(height: 12),
                  _buildHexagramStructureSection(),
                  const SizedBox(height: 12),
                  _buildBodyUseSection(),
                  const SizedBox(height: 12),
                  _buildWuXingSection(),
                  const SizedBox(height: 12),
                  AIAnalysisWidget(
                    result: result,
                    question: question.isEmpty ? null : question,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _loadQuestion(BuildContext context) {
    final repository = _tryReadRepository(context);
    final fallback = result.questionId.isNotEmpty ? result.questionId : null;
    return repository?.readEncryptedField('question_${result.id}') ??
        Future<String?>.value(fallback);
  }

  DivinationRepository? _tryReadRepository(BuildContext context) {
    try {
      return context.read<DivinationRepository>();
    } catch (_) {
      return null;
    }
  }

  // --- §9.1 占问事项 ------------------------------------------------------

  Widget _buildQuestionSection(String question) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '占问事项'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Text(
            question.isEmpty ? '未设置' : question,
            style: AppTextStyles.antiqueBody.copyWith(
              color: question.isEmpty ? AppColors.qianhe : AppColors.xuanse,
            ),
          ),
        ],
      ),
    );
  }

  // --- §9.3 排盘总览 ------------------------------------------------------

  Widget _buildOverviewSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '排盘总览'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          _buildInfoRow('本卦', result.benGua.name),
          _buildInfoRow('变卦', result.bianGua.name),
          _buildInfoRow('互卦', result.huGua.name),
          _buildInfoRow('动爻', result.movingLineLabel),
          _buildInfoRow('体卦', '${result.tiGua.name}·${result.tiGua.symbol}'),
          _buildInfoRow(
              '用卦', '${result.yongGua.name}·${result.yongGua.symbol}'),
          _buildInfoRow('体用', result.wuXingRelation),
        ],
      ),
    );
  }

  // --- §9.4 起卦依据 ------------------------------------------------------

  Widget _buildSourceSection() {
    final source = result.source;
    final rows = <Widget>[
      _buildInfoRow('方式', source.methodLabel),
    ];

    switch (result.castMethod) {
      case CastMethod.time:
        rows.addAll([
          _buildInfoRow(
            '年支',
            '${source.yearBranch ?? '-'}（数 ${source.yearNumber ?? '-'}）',
          ),
          _buildInfoRow('月数', '${source.monthNumber ?? '-'}'),
          _buildInfoRow('日数', '${source.dayNumber ?? '-'}'),
          _buildInfoRow(
            '时支',
            '${source.hourBranch ?? '-'}（数 ${source.hourNumber ?? '-'}）',
          ),
          _buildInfoRow(
            '上卦',
            '${source.upperRawValue ?? '-'} % 8 = ${source.upperNumber} → '
                '${result.benGua.upperTrigram.name}',
          ),
          _buildInfoRow(
            '下卦',
            '${source.lowerRawValue ?? '-'} % 8 = ${source.lowerNumber} → '
                '${result.benGua.lowerTrigram.name}',
          ),
          _buildInfoRow(
            '动爻',
            '${source.movingRawValue ?? '-'} % 6 = ${source.movingLineNumber} → '
                '${result.movingLineLabel}',
          ),
        ]);
      case CastMethod.number:
        rows.addAll([
          _buildInfoRow('上卦数', '${source.upperInputNumber ?? '-'}'),
          _buildInfoRow('下卦数', '${source.lowerInputNumber ?? '-'}'),
          _buildInfoRow(
            '上卦',
            '${source.upperInputNumber ?? '-'} % 8 = ${source.upperNumber} → '
                '${result.benGua.upperTrigram.name}',
          ),
          _buildInfoRow(
            '下卦',
            '${source.lowerInputNumber ?? '-'} % 8 = ${source.lowerNumber} → '
                '${result.benGua.lowerTrigram.name}',
          ),
          _buildInfoRow(
            '动爻',
            '${source.movingRawValue ?? '-'} % 6 = ${source.movingLineNumber} → '
                '${result.movingLineLabel}',
          ),
        ]);
      case CastMethod.manual:
        rows.addAll([
          _buildInfoRow('上卦', source.manualUpperTrigram ?? '-'),
          _buildInfoRow('下卦', source.manualLowerTrigram ?? '-'),
          _buildInfoRow('动爻', result.movingLineLabel),
          _buildInfoRow('来源', '手动指定'),
        ]);
      default:
        break;
    }

    if (source.note != null) {
      rows.add(const SizedBox(height: 4));
      rows.add(
        Text(
          source.note!,
          style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
        ),
      );
    }

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '起卦依据'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  // --- §9.5 卦象结构（三张自绘卦图） ---------------------------------------

  Widget _buildHexagramStructureSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '卦象结构'),
          const AntiqueDivider(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MeiHuaHexagramDiagram(
                  label: '本卦',
                  hexagram: result.benGua,
                  movingLine: result.movingLine,
                  tiName: result.tiGua.name,
                  yongName: result.yongGua.name,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MeiHuaHexagramDiagram(
                  label: '变卦',
                  hexagram: result.bianGua,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MeiHuaHexagramDiagram(
                  label: '互卦',
                  hexagram: result.huGua,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- §9.6 体用关系 ------------------------------------------------------

  Widget _buildBodyUseSection() {
    final lineSide = result.movingLine <= 3 ? '下卦' : '上卦';

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '体用关系'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          _buildInfoRow('动爻位置', '$lineSide（${result.movingLineLabel}）'),
          _buildInfoRow(
            '体卦',
            '${result.tiGua.name}·${result.tiGua.symbol}（${result.tiGua.wuXing}）',
          ),
          _buildInfoRow(
            '用卦',
            '${result.yongGua.name}·${result.yongGua.symbol}（${result.yongGua.wuXing}）',
          ),
          const SizedBox(height: 4),
          Text(
            result.bodyUseRule,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // --- §9.7 五行生克 ------------------------------------------------------

  Widget _buildWuXingSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '五行生克'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.meihuaColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.meihuaColor.withOpacity(0.4)),
              ),
              child: Text(
                result.wuXingRelation,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.meihuaColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            '体五行',
            '${result.tiGua.wuXing}（${result.tiGua.name}）',
          ),
          _buildInfoRow(
            '用五行',
            '${result.yongGua.wuXing}（${result.yongGua.name}）',
          ),
        ],
      ),
    );
  }

  // --- helpers -----------------------------------------------------------

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.antiqueBody),
          ),
        ],
      ),
    );
  }
}
