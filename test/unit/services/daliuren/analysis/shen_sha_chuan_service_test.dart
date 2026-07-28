import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/san_chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/shen_sha.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/shen_sha_chuan_service.dart';

Chuan _chuan(ChuanPosition position, String branch) => Chuan(
      position: position,
      diZhi: branch,
      wuXing: '木',
      chengShen: ShenJiang.guiRen,
      liuQin: '兄弟',
    );

void main() {
  test('普通神煞与驿马发用使用稳定 project rule IDs', () {
    final sanChuan = SanChuan(
      chuChuan: _chuan(ChuanPosition.chu, '寅'),
      zhongChuan: _chuan(ChuanPosition.zhong, '午'),
      moChuan: _chuan(ChuanPosition.mo, '戌'),
      keType: KeType.zeiKe,
    );
    final tags = ShenShaChuanService.analyze(
      sanChuan: sanChuan,
      shenShaList: const ShenShaList(
        allShenSha: <ShenSha>[
          ShenSha(
            name: '驿马',
            type: ShenShaType.zhong,
            diZhi: '寅',
            description: '主迁动',
          ),
          ShenSha(
            name: '天喜',
            type: ShenShaType.ji,
            diZhi: '午',
            description: '主喜庆',
          ),
        ],
      ),
    );

    final yiMa = tags[ChuanPosition.chu]!.single;
    final tianXi = tags[ChuanPosition.zhong]!.single;
    expect(yiMa.term, '驿马发用');
    expect(
      yiMa.ruleRef.ruleId,
      DlrProjectRuleIds.travellingHorseInitial,
    );
    expect(tianXi.term, '天喜临中传');
    expect(
      tianXi.ruleRef.ruleId,
      DlrProjectRuleIds.shenShaOnTransmission,
    );
  });
}
