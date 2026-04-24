import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../divination_systems/liuyao/models/gua.dart';
import '../../divination_systems/liuyao/models/yao.dart';
import '../../domain/services/fushen_service.dart';

/// 六爻紧凑表格组件
///
/// 当提供 `secondaryGua` 时，会将本卦、动爻标记和变卦放在同一张表格中，
/// 确保每一行的动爻标记与对应的爻位对齐。
class LiuYaoTableWidget extends StatelessWidget {
  /// 本卦
  final Gua gua;

  /// 变卦（可选）
  final Gua? secondaryGua;

  /// 六神列表
  final List<String> liuShen;

  /// 本卦标题
  final String title;

  /// 变卦标题
  final String? secondaryTitle;

  /// 是否显示世应列（仅本卦）
  final bool showWorldResponse;

  /// 变卦是否显示世应列（默认 false）
  final bool secondaryShowWorldResponse;

  const LiuYaoTableWidget({
    super.key,
    required this.gua,
    required this.liuShen,
    required this.title,
    this.secondaryGua,
    this.secondaryTitle,
    this.showWorldResponse = true,
    this.secondaryShowWorldResponse = false,
  });

  @override
  Widget build(BuildContext context) {
    if (secondaryGua == null) {
      return _buildSingleTable(context);
    }
    return _buildComparisonTable(context);
  }

  Widget _buildSingleTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderCard(
          context,
          title: title,
          guaName: gua.name,
          palace: gua.baGong.name,
          specialType: gua.specialType,
          gua: gua,
        ),
        const SizedBox(height: 8),
        _buildSingleTableBody(context),
      ],
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHeaderCard(
                context,
                title: title,
                guaName: gua.name,
                palace: gua.baGong.name,
                specialType: gua.specialType,
                gua: gua,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHeaderCard(
                context,
                title: secondaryTitle ?? '变卦',
                guaName: secondaryGua!.name,
                palace: secondaryGua!.baGong.name,
                specialType: secondaryGua!.specialType,
                gua: secondaryGua,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildComparisonTableBody(context),
      ],
    );
  }

  /// 构建单表体
  Widget _buildSingleTableBody(BuildContext context) {
    final fuShenByPosition = FuShenService.calculateFuShen(gua);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildSegmentHeaderRow(context, showWorldResponse),
          ...List.generate(6, (i) {
            final yaoIndex = 5 - i;
            final yao = gua.yaos[yaoIndex];
            final liuShenName =
                liuShen.length > yaoIndex ? liuShen[yaoIndex] : '';
            final isLastRow = i == 5;
            return _buildSegmentDataRow(
              context,
              yao: yao,
              fuShenText: fuShenByPosition[yao.position]?.displayText,
              liuShenName: liuShenName,
              showWorldResponse: showWorldResponse,
              isLastRow: isLastRow,
            );
          }),
        ],
      ),
    );
  }

  /// 构建对比表体（本卦 + 动爻 + 变卦）
  Widget _buildComparisonTableBody(BuildContext context) {
    final borderColor = Colors.grey.shade300;
    final fuShenByPosition = FuShenService.calculateFuShen(gua);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                ..._buildSegmentHeader(showWorldResponse),
                _buildMovingHeaderCell(),
                ..._buildSegmentHeader(secondaryShowWorldResponse),
              ],
            ),
          ),
          ...List.generate(6, (i) {
            final yaoIndex = 5 - i;
            final mainYao = gua.yaos[yaoIndex];
            final secondaryYao = secondaryGua!.yaos[yaoIndex];
            final liuShenName =
                liuShen.length > yaoIndex ? liuShen[yaoIndex] : '';
            final isLastRow = i == 5;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: isLastRow
                        ? null
                        : Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                  ),
                  child: Row(
                    children: [
                      ..._buildSegmentRowCells(
                        yao: mainYao,
                        liuShenName: liuShenName,
                        showWorldResponse: showWorldResponse,
                      ),
                      _buildMovingCell(mainYao.isMoving),
                      ..._buildSegmentRowCells(
                        yao: secondaryYao,
                        liuShenName: liuShenName,
                        showWorldResponse: secondaryShowWorldResponse,
                      ),
                    ],
                  ),
                ),
                _buildFuShenNote(
                  fuShenByPosition[mainYao.position]?.displayText,
                  showWorldResponse: showWorldResponse,
                  includeMovingColumn: true,
                  includeSecondarySegment: true,
                  secondaryShowWorldResponse: secondaryShowWorldResponse,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context, {
    required String title,
    required String guaName,
    required String palace,
    required GuaSpecialType specialType,
    Gua? gua,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  // 表头分区标签（结构性）
                  style: AppTextStyles.antiqueLabel.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  palace,
                  // 八宫名称（结构性次标题）
                  style: AppTextStyles.antiqueBody,
                ),
                const SizedBox(height: 2),
                Text(
                  guaName,
                  // 卦名（结构性标题）
                  style: AppTextStyles.antiqueBody.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (specialType != GuaSpecialType.none) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getSpecialTypeColor(specialType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      specialType.name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (gua != null) ...[
            const SizedBox(width: 16),
            _buildCompactGuaSymbol(gua),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactGuaSymbol(Gua gua) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: List.generate(6, (i) {
          final yao = gua.yaos[5 - i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              _getYaoSymbol(yao),
              // 爻象符号；red.shade700 = 动爻标记色（领域色，保留内联）
              style: TextStyle(
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.bold,
                color: yao.isMoving ? Colors.red.shade700 : Colors.black87,
                letterSpacing: 0,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSegmentHeaderRow(BuildContext context, bool showWorld) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: _buildSegmentHeader(showWorld),
      ),
    );
  }

  List<Widget> _buildSegmentHeader(bool showWorld) {
    // 本卦列：六神 | 六亲 | 世应
    // 变卦列：六亲 | 世应（可选）
    final widgets = <Widget>[];

    // 六神列（仅本卦显示）
    if (showWorld) {
      widgets.add(_buildCell('六神', flex: 2, isHeader: true));
    }

    // 六亲列
    widgets.add(_buildCell('六亲', flex: 3, isHeader: true));

    // 世应列
    if (showWorld) {
      widgets.add(_buildCell('世应', flex: 2, isHeader: true));
    }

    return widgets;
  }

  Widget _buildSegmentDataRow(
    BuildContext context, {
    required Yao yao,
    String? fuShenText,
    required String liuShenName,
    required bool showWorldResponse,
    bool isLastRow = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLastRow
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主行：爻的信息
          Row(
            children: _buildSegmentRowCells(
              yao: yao,
              liuShenName: liuShenName,
              showWorldResponse: showWorldResponse,
            ),
          ),
          _buildFuShenNote(
            fuShenText,
            showWorldResponse: showWorldResponse,
          ),
        ],
      ),
    );
  }

  Widget _buildFuShenNote(
    String? fuShenText, {
    required bool showWorldResponse,
    bool includeMovingColumn = false,
    bool includeSecondarySegment = false,
    bool secondaryShowWorldResponse = false,
  }) {
    if (fuShenText == null) {
      return const SizedBox.shrink();
    }

    return _buildFuShenRow(
      fuShenText,
      showWorldResponse: showWorldResponse,
      includeMovingColumn: includeMovingColumn,
      includeSecondarySegment: includeSecondarySegment,
      secondaryShowWorldResponse: secondaryShowWorldResponse,
    );
  }

  Widget _buildFuShenRow(
    String fuShenText, {
    required bool showWorldResponse,
    required bool includeMovingColumn,
    required bool includeSecondarySegment,
    required bool secondaryShowWorldResponse,
  }) {
    return Row(
      children: [
        if (showWorldResponse) const Spacer(flex: 2),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              '伏神：$fuShenText',
              // 伏神注记（领域色：朱砂系，保留内联）
              style: TextStyle(
                fontSize: 9,
                color: Colors.red.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        if (showWorldResponse) const Spacer(flex: 2),
        if (includeMovingColumn) const SizedBox(width: 48),
        if (includeSecondarySegment) ...[
          if (secondaryShowWorldResponse) const Spacer(flex: 2),
          const Expanded(flex: 3, child: SizedBox.shrink()),
          if (secondaryShowWorldResponse) const Spacer(flex: 2),
        ],
      ],
    );
  }

  List<Widget> _buildSegmentRowCells({
    required Yao yao,
    required String liuShenName,
    required bool showWorldResponse,
  }) {
    final widgets = <Widget>[];

    // 六神列（仅本卦显示）
    if (showWorldResponse) {
      widgets.add(
        _buildCell(
          liuShenName,
          flex: 2,
          // 六神名称（结构性标签）
          textStyle: AppTextStyles.antiqueLabel,
        ),
      );
    }

    // 六亲列（合并）
    widgets.add(
      _buildCell(
        _formatYaoRelation(yao),
        flex: 3,
        // 六亲（结构性正文）
        textStyle: AppTextStyles.antiqueLabel.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    // 世应列
    if (showWorldResponse) {
      widgets.add(
        _buildCell(
          yao.isSeYao
              ? '世'
              : yao.isYingYao
                  ? '应'
                  : '',
          flex: 2,
          // 世爻=红、应爻=蓝（领域色：世应指示色，保留内联）
          textStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: yao.isSeYao
                ? Colors.red
                : yao.isYingYao
                    ? Colors.blue
                    : Colors.black87,
          ),
        ),
      );
    }

    return widgets;
  }

  String _formatYaoRelation(Yao yao) =>
      '${yao.liuQin.name}${yao.stem}${yao.branch}${yao.wuXing.name}';

  /// 获取爻的符号表示
  String _getYaoSymbol(Yao yao) {
    // 阳爻：▅▅▅▅▅ 或 ━━━━
    // 阴爻：▅▅　▅▅ 或 ━━　━━
    if (yao.isYang) {
      return '━━━';
    } else {
      return '━    ━';
    }
  }

  Widget _buildMovingHeaderCell() {
    return Container(
      width: 48,
      alignment: Alignment.center,
      child: Text(
        '动爻',
        // 动爻列标头（结构性标签）
        style: AppTextStyles.antiqueLabel.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMovingCell(bool isMoving) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      child: isMoving
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '╳',
                  // 动爻标记符（领域色：动爻指示色，保留内联）
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Colors.red.shade700,
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  /// 获取特殊类型对应的颜色
  Color _getSpecialTypeColor(GuaSpecialType type) {
    switch (type) {
      case GuaSpecialType.liuChong:
        return Colors.red.shade600;
      case GuaSpecialType.liuHe:
        return Colors.green.shade600;
      case GuaSpecialType.youHun:
        return Colors.purple.shade600;
      case GuaSpecialType.guiHun:
        return Colors.blue.shade600;
      case GuaSpecialType.none:
        return Colors.grey;
    }
  }

  /// 构建单元格
  Widget _buildCell(
    String text, {
    required int flex,
    bool isHeader = false,
    TextStyle? textStyle,
    bool noEllipsis = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          text,
          // 单元格样式：表头=结构性标签，正文=结构性正文
          style: isHeader
              ? AppTextStyles.antiqueLabel.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : textStyle ?? AppTextStyles.antiqueBody,
          textAlign: TextAlign.center,
          overflow: noEllipsis ? TextOverflow.clip : TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
