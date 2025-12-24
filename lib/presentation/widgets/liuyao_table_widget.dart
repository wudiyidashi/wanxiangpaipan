import 'package:flutter/material.dart';
import '../../divination_systems/liuyao/models/gua.dart';
import '../../divination_systems/liuyao/models/yao.dart';

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

            return Container(
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  palace,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  guaName,
                  style: const TextStyle(
                    fontSize: 14,
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
    // 本卦列：六神 | 六亲地支 | 世应
    // 变卦列：六亲地支 | 世应（可选）
    final widgets = <Widget>[];

    // 六神列（仅本卦显示）
    if (showWorld) {
      widgets.add(_buildCell('六神', flex: 2, isHeader: true));
    }

    // 六亲地支列
    widgets.add(_buildCell('六亲地支', flex: 3, isHeader: true));

    // 世应列
    if (showWorld) {
      widgets.add(_buildCell('世应', flex: 2, isHeader: true));
    }

    return widgets;
  }

  Widget _buildSegmentDataRow(
    BuildContext context, {
    required Yao yao,
    required String liuShenName,
    required bool showWorldResponse,
    bool isLastRow = false,
  }) {
    // TODO: 从数据源获取伏神信息
    final fuShenText = _getFuShenText(yao);

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

          // 伏神行（如果有）
          if (fuShenText != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                '（$fuShenText）',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.red.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 获取伏神文本
  /// TODO: 实现伏神计算逻辑，从数据源获取伏神信息
  String? _getFuShenText(Yao yao) {
    // 临时示例：仅用于演示伏神显示效果
    // 实际应该从卦象计算逻辑中获取
    return null;
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
          textStyle: const TextStyle(fontSize: 11),
        ),
      );
    }

    // 六亲地支列（合并）
    widgets.add(
      _buildCell(
        '${yao.liuQin.name}${yao.branch}${yao.wuXing.name}',
        flex: 3,
        textStyle: const TextStyle(
          fontSize: 11,
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
      child: const Text(
        '动爻',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
          style: isHeader
              ? const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                )
              : textStyle ??
                  const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
          textAlign: TextAlign.center,
          overflow: noEllipsis ? TextOverflow.clip : TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
