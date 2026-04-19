import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../models/chuan.dart';
import '../models/daliuren_result.dart';

class DaLiuRenPanParamsSection extends StatelessWidget {
  const DaLiuRenPanParamsSection({
    super.key,
    required this.question,
    required this.ganZhiText,
    required this.dunGanText,
    required this.yueJiangText,
    required this.guiRenText,
  });

  final String question;
  final String ganZhiText;
  final String dunGanText;
  final String yueJiangText;
  final String guiRenText;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '排盘参数'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          DaLiuRenInfoRow('占问', question.isEmpty ? '未设置' : question),
          DaLiuRenInfoRow('干支', ganZhiText),
          DaLiuRenInfoRow('遁干', dunGanText),
          DaLiuRenInfoRow('月将', yueJiangText),
          DaLiuRenInfoRow('贵神', guiRenText),
        ],
      ),
    );
  }
}

class DaLiuRenSiKeSection extends StatelessWidget {
  const DaLiuRenSiKeSection({
    super.key,
    required this.result,
  });

  final DaLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    final keList = [
      result.siKe.ke4,
      result.siKe.ke3,
      result.siKe.ke2,
      result.siKe.ke1,
    ];
    const keLabels = ['四课', '三课', '二课', '一课'];

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '四课'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(
              color: AppColors.danjin.withOpacity(0.5),
              width: 1,
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.danjin.withOpacity(0.1),
                ),
                children: keLabels.map((label) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: Text(
                          label,
                          style: AppTextStyles.antiqueBody.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.guhe,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              TableRow(
                children: keList.map((ke) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          ke.shangShen,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                ke.hasKe ? AppColors.zhusha : AppColors.xuanse,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              TableRow(
                children: keList.map((ke) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          ke.xiaShen,
                          style: AppTextStyles.antiqueTitle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: keList.map((ke) {
              return Expanded(
                child: Center(
                  child: Text(
                    ke.wuXingRelation ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: ke.isZeiKe
                          ? AppColors.zhusha
                          : ke.isBiYong
                              ? AppColors.biyongBlue
                              : AppColors.guhe,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class DaLiuRenSanChuanSection extends StatelessWidget {
  const DaLiuRenSanChuanSection({
    super.key,
    required this.result,
  });

  final DaLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '三传'),
          const AntiqueDivider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DaLiuRenChuanCircle(
                  label: '初传', chuan: result.sanChuan.chuChuan),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child:
                    Icon(Icons.arrow_forward, size: 18, color: AppColors.guhe),
              ),
              _DaLiuRenChuanCircle(
                  label: '中传', chuan: result.sanChuan.zhongChuan),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child:
                    Icon(Icons.arrow_forward, size: 18, color: AppColors.guhe),
              ),
              _DaLiuRenChuanCircle(label: '末传', chuan: result.sanChuan.moChuan),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.zhusha.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.zhusha.withOpacity(0.3)),
              ),
              child: Text(
                '${result.keTypeName}课',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.zhusha,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (result.sanChuan.keTypeExplanation != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                result.sanChuan.keTypeExplanation!,
                style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DaLiuRenTianPanSection extends StatelessWidget {
  const DaLiuRenTianPanSection({
    super.key,
    required this.result,
  });

  final DaLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '天盘'),
          const AntiqueDivider(),
          const SizedBox(height: 4),
          DaLiuRenInfoRow(
            '月将',
            '${result.tianPan.yueJiang}（${result.tianPan.yueJiangName}）',
          ),
          DaLiuRenInfoRow('描述', result.tianPan.yueJiangDescription),
          const SizedBox(height: 12),
          DaLiuRenGridSection(
            items: result.tianPan.fullDisplay
                .map(
                  (item) => DaLiuRenGridItem(
                    title: '${item['地盘']}宫',
                    primary: item['天盘'] ?? '',
                    secondary: '天地盘',
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DaLiuRenShenJiangSection extends StatelessWidget {
  const DaLiuRenShenJiangSection({
    super.key,
    required this.result,
  });

  final DaLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '十二神将'),
          const AntiqueDivider(),
          const SizedBox(height: 4),
          DaLiuRenInfoRow(
            '贵人',
            '${result.shenJiangConfig.guiRenPosition}（${result.shenJiangConfig.guiRenTypeDescription}）',
          ),
          DaLiuRenInfoRow('布神', result.shenJiangConfig.directionDescription),
          const SizedBox(height: 12),
          DaLiuRenGridSection(
            items: result.shenJiangConfig.positions
                .map(
                  (pos) => DaLiuRenGridItem(
                    title: pos.name,
                    primary: pos.diZhi,
                    secondary: '乘${pos.tianPanZhi}',
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DaLiuRenShenShaSection extends StatelessWidget {
  const DaLiuRenShenShaSection({
    super.key,
    required this.result,
  });

  final DaLiuRenResult result;

  @override
  Widget build(BuildContext context) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '神煞'),
          const AntiqueDivider(),
          if (result.shenShaList.jiShen.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '吉神',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.jishenGreen,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.shenShaList.jiShen.map((shenSha) {
                return _DaLiuRenShenShaTag(
                  text: shenSha.displayText,
                  color: AppColors.jishenGreen,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (result.shenShaList.xiongShen.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '凶神',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.zhusha,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.shenShaList.xiongShen.map((shenSha) {
                return _DaLiuRenShenShaTag(
                  text: shenSha.displayText,
                  color: AppColors.zhusha,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class DaLiuRenInfoRow extends StatelessWidget {
  const DaLiuRenInfoRow(
    this.label,
    this.value, {
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: AppTextStyles.antiqueBody.copyWith(
                color: AppColors.guhe,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.antiqueBody,
            ),
          ),
        ],
      ),
    );
  }
}

class DaLiuRenGridSection extends StatelessWidget {
  const DaLiuRenGridSection({
    super.key,
    required this.items,
  });

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }
}

class DaLiuRenGridItem extends StatelessWidget {
  const DaLiuRenGridItem({
    super.key,
    required this.title,
    required this.primary,
    required this.secondary,
  });

  final String title;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danjin.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            primary,
            style: AppTextStyles.antiqueTitle.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            secondary,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DaLiuRenChuanCircle extends StatelessWidget {
  const _DaLiuRenChuanCircle({
    required this.label,
    required this.chuan,
  });

  final String label;
  final Chuan chuan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.zhusha, AppColors.zhushaLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.zhusha.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                chuan.diZhi,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chuan.liuQin,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            chuan.chengShenName,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
          if (chuan.isKongWang) ...[
            const SizedBox(height: 2),
            Text(
              '空亡',
              style: AppTextStyles.antiqueLabel.copyWith(
                fontSize: 11,
                color: AppColors.zhusha,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DaLiuRenShenShaTag extends StatelessWidget {
  const _DaLiuRenShenShaTag({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}
