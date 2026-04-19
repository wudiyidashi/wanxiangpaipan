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
import '../models/xiaoliuren_result.dart';
import '../xiaoliuren_system.dart';
import 'xiaoliuren_chain_view.dart';

/// 小六壬 UI 工厂
///
/// 统一起课界面（方式 + 盘式 + method-specific body），
/// 结果页按 `docs/architecture/divination-systems/xiaoliuren.md §11.1` 铺 7 块，
/// 不渲染占断段——占断交 AI 分析卡片。
class XiaoLiuRenUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.xiaoLiuRen;

  @override
  Widget buildCastScreen(CastMethod method) => const _XiaoLiuRenCastScreen();

  @override
  Widget buildResultScreen(DivinationResult result) {
    if (result is! XiaoLiuRenResult) {
      throw ArgumentError(
        '结果类型必须是 XiaoLiuRenResult，实际类型: ${result.runtimeType}',
      );
    }
    return _XiaoLiuRenResultScreen(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) =>
      HistoryRecordCard(result: result);

  @override
  IconData? getSystemIcon() => Icons.hub;

  @override
  Color? getSystemColor() => AppColors.xiaoliurenColor;
}

// ============================================================
// 统一起课界面
// ============================================================

class _XiaoLiuRenCastScreen extends StatefulWidget {
  const _XiaoLiuRenCastScreen();

  @override
  State<_XiaoLiuRenCastScreen> createState() => _XiaoLiuRenCastScreenState();
}

class _XiaoLiuRenCastScreenState extends State<_XiaoLiuRenCastScreen> {
  static const List<CastMethod> _availableMethods = [
    CastMethod.time,
    CastMethod.reportNumber,
    CastMethod.characterStroke,
  ];

  static const Map<CastMethod, String> _methodLabels = {
    CastMethod.time: '时间起课',
    CastMethod.reportNumber: '报数起课',
    CastMethod.characterStroke: '汉字笔画起',
  };

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _firstNumberController = TextEditingController();
  final TextEditingController _secondNumberController = TextEditingController();
  final TextEditingController _thirdNumberController = TextEditingController();
  final TextEditingController _firstStrokeController = TextEditingController();
  final TextEditingController _secondStrokeController = TextEditingController();
  final TextEditingController _thirdStrokeController = TextEditingController();

  CastMethod _selectedMethod = CastMethod.time;
  XiaoLiuRenPalaceMode _palaceMode = XiaoLiuRenPalaceMode.sixPalaces;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastMethod();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _firstNumberController.dispose();
    _secondNumberController.dispose();
    _thirdNumberController.dispose();
    _firstStrokeController.dispose();
    _secondStrokeController.dispose();
    _thirdStrokeController.dispose();
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
      DivinationType.xiaoLiuRen,
      allowed: _availableMethods,
    );
    if (method != null && mounted) {
      setState(() => _selectedMethod = method);
    }
  }

  Future<void> _handleCast() async {
    if (_isLoading) return;

    final Map<String, dynamic> input;
    switch (_selectedMethod) {
      case CastMethod.time:
        input = {'palaceMode': _palaceMode.id};
      case CastMethod.reportNumber:
        final first = int.tryParse(_firstNumberController.text.trim());
        final second = int.tryParse(_secondNumberController.text.trim());
        final third = int.tryParse(_thirdNumberController.text.trim());
        if (first == null || first <= 0) {
          _showError('请输入有效的数一');
          return;
        }
        if (second == null || second <= 0) {
          _showError('请输入有效的数二');
          return;
        }
        if (third == null || third <= 0) {
          _showError('请输入有效的数三');
          return;
        }
        input = {
          'firstNumber': first,
          'secondNumber': second,
          'thirdNumber': third,
          'palaceMode': _palaceMode.id,
        };
      case CastMethod.characterStroke:
        final first = int.tryParse(_firstStrokeController.text.trim());
        final second = int.tryParse(_secondStrokeController.text.trim());
        final third = int.tryParse(_thirdStrokeController.text.trim());
        if (first == null || first <= 0) {
          _showError('请输入有效的首字笔画');
          return;
        }
        if (second == null || second <= 0) {
          _showError('请输入有效的次字笔画');
          return;
        }
        if (third == null || third <= 0) {
          _showError('请输入有效的末字笔画');
          return;
        }
        input = {
          'firstStroke': first,
          'secondStroke': second,
          'thirdStroke': third,
          'palaceMode': _palaceMode.id,
        };
      default:
        _showError('小六壬不支持该起课方式');
        return;
    }

    setState(() => _isLoading = true);
    try {
      final system = XiaoLiuRenSystem();
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
        debugPrint('XiaoLiuRen: failed to save record: $saveError');
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              _XiaoLiuRenResultScreen(result: result as XiaoLiuRenResult),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('起课失败: $e');
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
      appBar: const AntiqueAppBar(title: '小六壬起课'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionSection(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMethodSelector()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPalaceModeSelector()),
                ],
              ),
              const SizedBox(height: 16),
              const AntiqueDivider(),
              const SizedBox(height: 20),
              _buildMethodBody(),
              const SizedBox(height: 24),
              AntiqueButton(
                label: _isLoading ? '起课中...' : '起课',
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
        const Text('起课方式', style: AppTextStyles.antiqueLabel),
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

  Widget _buildPalaceModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('盘式', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<XiaoLiuRenPalaceMode>(
          value: _palaceMode,
          items: XiaoLiuRenPalaceMode.values
              .map(
                (m) => AntiqueDropdownItem<XiaoLiuRenPalaceMode>(
                  value: m,
                  label: m.displayName,
                ),
              )
              .toList(),
          onChanged: (m) {
            if (m != null) setState(() => _palaceMode = m);
          },
        ),
      ],
    );
  }

  Widget _buildMethodBody() {
    switch (_selectedMethod) {
      case CastMethod.time:
        return _buildTimeBody();
      case CastMethod.reportNumber:
        return _buildNumberTripleBody(
          title: '报三数',
          labels: const ['数一', '数二', '数三'],
          controllers: [
            _firstNumberController,
            _secondNumberController,
            _thirdNumberController,
          ],
          note: '大安起第一数，首位上起第二数，次位上起第三数',
        );
      case CastMethod.characterStroke:
        return _buildNumberTripleBody(
          title: '三段笔画',
          labels: const ['首字笔画', '次字笔画', '末字笔画'],
          controllers: [
            _firstStrokeController,
            _secondStrokeController,
            _thirdStrokeController,
          ],
          note: '请先人工数好三段笔画再输入；当前底层不做自动汉字转笔画',
        );
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
    final lunarDate = '农历${lunar.getMonthInChinese()}月'
        '${lunar.getDayInChinese()} ${lunar.getTimeZhi()}时';

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
              color: AppColors.xiaoliurenColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lunarDate,
            style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
          ),
          const SizedBox(height: 6),
          Text(
            '取农历月数、农历日数、时支序数作为三段起数',
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberTripleBody({
    required String title,
    required List<String> labels,
    required List<TextEditingController> controllers,
    required String note,
  }) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: title),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: _buildNumberField(
                    label: labels[i],
                    controller: controllers[i],
                  ),
                ),
                if (i < 2) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
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
              hintText: '正整数',
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
}

// ============================================================
// 结果页
// ============================================================

class _XiaoLiuRenResultScreen extends StatelessWidget {
  final XiaoLiuRenResult result;

  const _XiaoLiuRenResultScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    final questionFuture = _loadQuestion(context);

    return FutureBuilder<String?>(
      future: questionFuture,
      builder: (context, snapshot) {
        final question = (snapshot.data ?? '').trim();
        return AntiqueScaffold(
          appBar: const AntiqueAppBar(title: '小六壬排课结果'),
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
                  _buildChainSection(),
                  const SizedBox(height: 12),
                  _buildFinalPositionSection(),
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

  // --- §11.1(1) 占问事项 --------------------------------------------------

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

  // --- §11.1(3) 排盘总览 --------------------------------------------------

  Widget _buildOverviewSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '排盘总览'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          _buildInfoRow('方式', result.source.methodLabel),
          _buildInfoRow('盘式', result.palaceMode.displayName),
          _buildInfoRow(
            '第一段',
            '${result.source.firstLabel} ${result.source.firstNumber} '
                '→ ${result.monthPosition.name}',
          ),
          _buildInfoRow(
            '第二段',
            '${result.source.secondLabel} ${result.source.secondNumber} '
                '→ ${result.dayPosition.name}',
          ),
          _buildInfoRow(
            '第三段',
            '${result.source.thirdLabel} ${result.source.thirdNumber} '
                '→ ${result.hourPosition.name}',
          ),
          _buildInfoRow(
            '最终落宫',
            '${result.finalPosition.name}（${result.finalPosition.fortune}）',
          ),
        ],
      ),
    );
  }

  // --- §11.1(4~5) 起课依据 -----------------------------------------------

  Widget _buildSourceSection() {
    final source = result.source;
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '起课依据'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          _buildInfoRow('规则', source.rule),
          _buildInfoRow(source.firstLabel, '${source.firstNumber}'),
          _buildInfoRow(source.secondLabel, '${source.secondNumber}'),
          _buildInfoRow(source.thirdLabel, '${source.thirdNumber}'),
          if (source.hourZhi != null) _buildInfoRow('时支', source.hourZhi!),
          if (source.note != null) ...[
            const SizedBox(height: 4),
            Text(
              source.note!,
              style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  // --- §11.1(6~7) 三段顺推链 ---------------------------------------------

  Widget _buildChainSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '三段顺推'),
          const AntiqueDivider(),
          const SizedBox(height: 14),
          XiaoLiuRenChainView(
            firstStepLabel: result.source.firstLabel,
            firstStepNumber: result.source.firstNumber,
            firstPosition: result.monthPosition,
            secondStepLabel: result.source.secondLabel,
            secondStepNumber: result.source.secondNumber,
            secondPosition: result.dayPosition,
            thirdStepLabel: result.source.thirdLabel,
            thirdStepNumber: result.source.thirdNumber,
            thirdPosition: result.hourPosition,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // --- §11.1(8) 最终落宫宫义 ---------------------------------------------

  Widget _buildFinalPositionSection() {
    final finalPos = result.finalPosition;
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '最终落宫'),
          const AntiqueDivider(),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.zhusha.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.zhusha.withOpacity(0.4)),
              ),
              child: Text(
                '${finalPos.name} · ${finalPos.keyword}',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.zhusha,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('吉凶', finalPos.fortune),
          _buildInfoRow('五行', finalPos.wuXing),
          _buildInfoRow('方位', finalPos.direction),
          const SizedBox(height: 6),
          Text(
            finalPos.description,
            style: AppTextStyles.antiqueBody.copyWith(height: 1.6),
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
            width: 64,
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
