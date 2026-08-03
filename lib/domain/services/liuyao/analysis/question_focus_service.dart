import '../../../../divination_systems/liuyao/liuyao_result.dart';
import '../../shared/wuxing_service.dart';
import 'tables/dizhi_relations.dart';

class LiuYaoQuestionFocusAspect {
  const LiuYaoQuestionFocusAspect({
    required this.aspectId,
    required this.role,
    required this.label,
    required this.verificationQuestions,
  });

  final String aspectId;
  final String role;
  final String label;
  final List<String> verificationQuestions;

  Map<String, Object?> toJson() => <String, Object?>{
        'aspectId': aspectId,
        'role': role,
        'label': label,
        'verificationQuestions': verificationQuestions,
      };
}

class LiuYaoQuestionFocus {
  const LiuYaoQuestionFocus({
    required this.focusId,
    required this.classification,
    required this.applicable,
    required this.autoSelectsUseSpirit,
    required this.aspects,
  });

  final String focusId;
  final String classification;
  final bool applicable;
  final bool autoSelectsUseSpirit;
  final List<LiuYaoQuestionFocusAspect> aspects;

  Map<String, Object?> toJson() => <String, Object?>{
        'focusId': focusId,
        'classification': classification,
        'applicable': applicable,
        'autoSelectsUseSpirit': autoSelectsUseSpirit,
        'aspects': aspects.map((aspect) => aspect.toJson()).toList(),
      };
}

class LiuYaoShiYingRelation {
  const LiuYaoShiYingRelation({
    required this.evidenceId,
    required this.shiActorId,
    required this.yingActorId,
    required this.direction,
    required this.isHarmony,
    required this.isClash,
  });

  final String evidenceId;
  final String shiActorId;
  final String yingActorId;
  final String direction;
  final bool isHarmony;
  final bool isClash;

  bool get supportsFormation => direction == 'yingGeneratesShi' || isHarmony;

  Map<String, Object?> toJson() => <String, Object?>{
        'evidenceId': evidenceId,
        'shiActorId': shiActorId,
        'yingActorId': yingActorId,
        'direction': direction,
        'isHarmony': isHarmony,
        'isClash': isClash,
        'authority': 'mechanicalObservation',
        'decisionScopes': const <String>['formation'],
      };
}

class LiuYaoQuestionFocusService {
  LiuYaoQuestionFocusService._();

  static LiuYaoQuestionFocus resolve(String? question) {
    final normalized = question?.trim() ?? '';
    final isRental = <String>['租房', '租赁', '房租', '出租'].any(normalized.contains);
    if (!isRental) {
      return const LiuYaoQuestionFocus(
        focusId: 'liuyao.focus.unspecified',
        classification: 'unspecified',
        applicable: false,
        autoSelectsUseSpirit: false,
        aspects: <LiuYaoQuestionFocusAspect>[],
      );
    }
    return const LiuYaoQuestionFocus(
      focusId: 'liuyao.focus.rental-full-cycle.v1',
      classification: 'rentalFullCycle',
      applicable: true,
      autoSelectsUseSpirit: false,
      aspects: <LiuYaoQuestionFocusAspect>[
        LiuYaoQuestionFocusAspect(
          aspectId: 'querent',
          role: 'shi',
          label: '求测者及其承受能力',
          verificationQuestions: <String>['求测者能否承担付款与履约暴露'],
        ),
        LiuYaoQuestionFocusAspect(
          aspectId: 'counterparty',
          role: 'ying',
          label: '交易对方及其履约表现',
          verificationQuestions: <String>['对方身份、权限与后续履约是否可靠'],
        ),
        LiuYaoQuestionFocusAspect(
          aspectId: 'formationAndDelivery',
          role: 'shiYing',
          label: '签约、入住与交付占有',
          verificationQuestions: <String>['能否签约或入住', '房屋能否实际交付占有'],
        ),
        LiuYaoQuestionFocusAspect(
          aspectId: 'feesAndExposure',
          role: 'qiCai',
          label: '付款、押金、费用与损失暴露',
          verificationQuestions: <String>['收费是否完整合理', '预付和追索风险如何'],
        ),
        LiuYaoQuestionFocusAspect(
          aspectId: 'contractAndAuthority',
          role: 'fuMu',
          label: '房屋、合同、权属与身份文书',
          verificationQuestions: <String>['出租权和合同主体是否可靠'],
        ),
        LiuYaoQuestionFocusAspect(
          aspectId: 'competitionAndDiversion',
          role: 'xiongDi',
          label: '竞争、额外费用与利益分流',
          verificationQuestions: <String>['是否存在竞争、催促或额外费用'],
        ),
        LiuYaoQuestionFocusAspect(
          aspectId: 'disputeAndContinuity',
          role: 'guanGui',
          label: '争议、风险与租期持续履约',
          verificationQuestions: <String>['完整租期能否持续', '对方后续履约是否稳定'],
        ),
      ],
    );
  }

  static LiuYaoShiYingRelation shiYingRelation(LiuYaoResult result) {
    final shi = result.seYao;
    final ying = result.yingYao;
    final direction = WuXingService.isSheng(ying.wuXing, shi.wuXing)
        ? 'yingGeneratesShi'
        : WuXingService.isSheng(shi.wuXing, ying.wuXing)
            ? 'shiGeneratesYing'
            : WuXingService.isKe(ying.wuXing, shi.wuXing)
                ? 'yingOvercomesShi'
                : WuXingService.isKe(shi.wuXing, ying.wuXing)
                    ? 'shiOvercomesYing'
                    : shi.wuXing == ying.wuXing
                        ? 'sameElement'
                        : 'neutral';
    return LiuYaoShiYingRelation(
      evidenceId:
          'liuyao.observation.shiying.${ying.position}-to-${shi.position}',
      shiActorId: 'main:yao:${shi.position}',
      yingActorId: 'main:yao:${ying.position}',
      direction: direction,
      isHarmony: DiZhiRelations.isLiuHe(shi.branch, ying.branch),
      isClash: DiZhiRelations.isLiuChong(shi.branch, ying.branch),
    );
  }
}
