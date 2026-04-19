import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/ke.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/pan_params.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/san_chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/shen_jiang_config.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/shen_sha.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/si_ke.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/tianpan.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

DaLiuRenResult _buildTestDaLiuRenResult(LunarInfo lunarInfo) {
  return DaLiuRenResult(
    id: 'test-id',
    castTime: DateTime(2025, 1, 16, 12, 0),
    castMethod: CastMethod.time,
    lunarInfo: lunarInfo,
    tianPan: TianPan(
      yueJiang: '子',
      yueJiangName: '神后',
      shiZhi: '子',
      tianPanMap: const <String, String>{
        '子': '子',
        '丑': '丑',
        '寅': '寅',
        '卯': '卯',
        '辰': '辰',
        '巳': '巳',
        '午': '午',
        '未': '未',
        '申': '申',
        '酉': '酉',
        '戌': '戌',
        '亥': '亥',
      },
    ),
    siKe: SiKe(
      ke1: Ke(
        index: 1,
        shangShen: '子',
        xiaShen: '子',
        chengShen: ShenJiang.guiRen,
        shangShenWuXing: '水',
        xiaShenWuXing: '水',
      ),
      ke2: Ke(
        index: 2,
        shangShen: '丑',
        xiaShen: '丑',
        chengShen: ShenJiang.tengShe,
        shangShenWuXing: '土',
        xiaShenWuXing: '土',
      ),
      ke3: Ke(
        index: 3,
        shangShen: '寅',
        xiaShen: '寅',
        chengShen: ShenJiang.zhuQue,
        shangShenWuXing: '木',
        xiaShenWuXing: '木',
      ),
      ke4: Ke(
        index: 4,
        shangShen: '卯',
        xiaShen: '卯',
        chengShen: ShenJiang.liuHe,
        shangShenWuXing: '木',
        xiaShenWuXing: '木',
      ),
      riGan: lunarInfo.riGan,
      riZhi: lunarInfo.riZhi,
    ),
    sanChuan: SanChuan(
      chuChuan: Chuan(
        position: ChuanPosition.chu,
        diZhi: '子',
        wuXing: '水',
        chengShen: ShenJiang.guiRen,
        liuQin: '兄弟',
      ),
      zhongChuan: Chuan(
        position: ChuanPosition.zhong,
        diZhi: '丑',
        wuXing: '土',
        chengShen: ShenJiang.tengShe,
        liuQin: '父母',
      ),
      moChuan: Chuan(
        position: ChuanPosition.mo,
        diZhi: '寅',
        wuXing: '木',
        chengShen: ShenJiang.zhuQue,
        liuQin: '妻财',
      ),
      keType: KeType.zeiKe,
    ),
    shenJiangConfig: ShenJiangConfig(
      guiRenPosition: '子',
      isYangGui: true,
      isYangRi: true,
      positions: <ShenJiangPosition>[
        ShenJiangPosition(
          shenJiang: ShenJiang.guiRen,
          diZhi: '子',
          tianPanZhi: '子',
        ),
      ],
      diZhiToShenJiang: <String, ShenJiang>{
        '子': ShenJiang.guiRen,
      },
    ),
    shenShaList: ShenShaList(
      allShenSha: <ShenSha>[],
    ),
    panParams: const DaLiuRenPanParams(),
  );
}

void main() {
  group('DaLiuRenSystem', () {
    late DaLiuRenSystem system;
    late LunarInfo testLunarInfo;

    setUp(() {
      system = DaLiuRenSystem();
      testLunarInfo = LunarInfo(
        yueJian: '丑',
        riGan: '戊',
        riZhi: '寅',
        riGanZhi: '戊寅',
        hourGanZhi: '甲子',
        yearGanZhi: '甲辰',
        monthGanZhi: '丁丑',
        kongWang: ['戌', '亥'],
      );
    });

    group('基本属性', () {
      test('应该返回正确的系统类型', () {
        expect(system.type, DivinationType.daLiuRen);
      });

      test('应该返回正确的系统名称', () {
        expect(system.name, '大六壬');
      });

      test('应该返回正确的系统描述', () {
        expect(system.description, isNotEmpty);
        expect(system.description, contains('大六壬'));
      });

      test('应该已启用（isEnabled = true）', () {
        expect(system.isEnabled, true);
      });

      test('应该支持时间起卦和手动输入', () {
        expect(system.supportedMethods, contains(CastMethod.time));
        expect(system.supportedMethods, contains(CastMethod.manual));
      });
    });

    group('cast 方法', () {
      test('应该返回时间起课结果', () async {
        final result = await system.cast(
          method: CastMethod.time,
          input: {},
        );

        expect(result, isA<DaLiuRenResult>());
        expect(result.castMethod, CastMethod.time);
      });

      test('应该返回手动起课结果', () async {
        final result = await system.cast(
          method: CastMethod.manual,
          input: {
            'yearGanZhi': '丙午',
            'monthGanZhi': '壬辰',
            'dayGanZhi': '壬戌',
            'hourGanZhi': '辛亥',
            'params': {
              'monthGeneralMode': 'manual',
              'manualMonthGeneral': '戌',
            },
          },
        );

        expect(result, isA<DaLiuRenResult>());
        expect(result.castMethod, CastMethod.manual);
      });

      test('旧 manual 输入格式应直接判定无效', () {
        expect(
          system.validateInput(
            CastMethod.manual,
            {
              'riGan': '甲',
              'riZhi': '子',
              'shiZhi': '子',
              'yueJian': '子',
            },
          ),
          false,
        );
      });

      test('手动月将参数应覆盖自动月将', () async {
        final result = await system.cast(
          method: CastMethod.time,
          input: {
            'params': {
              'monthGeneralMode': 'manual',
              'manualMonthGeneral': '酉',
            },
          },
          castTime: DateTime(2026, 4, 18, 22, 20),
        );

        final dlr = result as DaLiuRenResult;
        expect(dlr.tianPan.yueJiang, '酉');
        expect(dlr.panParams.monthGeneralMode, DaLiuRenMonthGeneralMode.manual);
      });

      test('时柱旬遁干应切换空亡主轴', () async {
        final result = await system.cast(
          method: CastMethod.time,
          input: {
            'params': {
              'xunShouMode': 'hour',
            },
          },
          castTime: DateTime(2026, 4, 18, 22, 20),
        );

        final dlr = result as DaLiuRenResult;
        expect(dlr.lunarInfo.hourGanZhi, '辛亥');
        expect(dlr.lunarInfo.kongWang, ['寅', '卯']);
      });

      test('固定样例应排出正统关键结构', () async {
        final result = await system.cast(
          method: CastMethod.time,
          input: {},
          castTime: DateTime(2026, 4, 18, 22, 20),
        );

        final dlr = result as DaLiuRenResult;
        expect(dlr.lunarInfo.yearGanZhi, '丙午');
        expect(dlr.lunarInfo.monthGanZhi, '壬辰');
        expect(dlr.lunarInfo.riGanZhi, '壬戌');
        expect(dlr.tianPan.yueJiang, '戌');

        expect(dlr.shenJiangConfig.guiRenPosition, '卯');
        expect(dlr.shenJiangConfig.guiRenTypeDescription, '阴贵（夜贵）');
        expect(dlr.shenJiangConfig.directionDescription, '夜课逆布');

        expect(dlr.siKe.ke1.shangShen, '戌');
        expect(dlr.siKe.ke1.xiaShen, '壬');
        expect(dlr.siKe.ke1.wuXingRelation, '上克下');

        expect(dlr.sanChuan.keType, KeType.zeiKe);
        expect(dlr.chuChuan, '戌');
        expect(dlr.zhongChuan, '酉');
        expect(dlr.moChuan, '申');

        expect(dlr.shenJiangConfig.getShenJiangByDiZhi('卯'), ShenJiang.guiRen);
        expect(
            dlr.shenJiangConfig.getShenJiangByDiZhi('申'), ShenJiang.qingLong);
        expect(
            dlr.shenJiangConfig.getShenJiangByDiZhi('酉'), ShenJiang.tianKong);
        expect(dlr.shenJiangConfig.getShenJiangByDiZhi('戌'), ShenJiang.baiHu);
      });
    });

    group('resultFromJson', () {
      test('应该能够从 JSON 反序列化结果', () {
        final DaLiuRenResult seedResult =
            _buildTestDaLiuRenResult(testLunarInfo);
        final Map<String, dynamic> json = seedResult.toJson();

        final result = system.resultFromJson(json);

        expect(result, isA<DaLiuRenResult>());
        expect(result.id, 'test-id');
        expect(result.systemType, DivinationType.daLiuRen);
        expect(result.castMethod, CastMethod.time);
      });
    });
  });

  group('DaLiuRenResult', () {
    late DaLiuRenResult result;
    late LunarInfo testLunarInfo;

    setUp(() {
      testLunarInfo = LunarInfo(
        yueJian: '丑',
        riGan: '戊',
        riZhi: '寅',
        riGanZhi: '戊寅',
        hourGanZhi: '甲子',
        yearGanZhi: '甲辰',
        monthGanZhi: '丁丑',
        kongWang: ['戌', '亥'],
      );

      result = _buildTestDaLiuRenResult(testLunarInfo);
    });

    test('应该返回正确的系统类型', () {
      expect(result.systemType, DivinationType.daLiuRen);
    });

    test('应该返回正确的摘要', () {
      expect(result.getSummary(), '贼克课 · 初传子 中传丑 末传寅');
    });

    test('应该能够序列化为 JSON', () {
      final json = result.toJson();

      expect(json['id'], 'test-id');
      expect(json['castMethod'], 'time');
      expect(json['lunarInfo'], isA<Map<String, dynamic>>());
      expect(json['tianPan'], isA<Map<String, dynamic>>());
      expect(json['siKe'], isA<Map<String, dynamic>>());
      expect(json['sanChuan'], isA<Map<String, dynamic>>());
      expect(json['shenJiangConfig'], isA<Map<String, dynamic>>());
      expect(json['shenShaList'], isA<Map<String, dynamic>>());
      expect(json['panParams'], isA<Map<String, dynamic>>());
    });

    test('应该能够从 JSON 反序列化', () {
      final json = result.toJson();
      final deserialized = DaLiuRenResult.fromJson(json);

      expect(deserialized.id, result.id);
      expect(deserialized.systemType, result.systemType);
      expect(deserialized.castTime, result.castTime);
      expect(deserialized.castMethod, result.castMethod);
    });
  });
}
