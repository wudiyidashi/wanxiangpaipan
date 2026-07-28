import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_cast_time.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
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
            'manualInputMode': 'rawPillars',
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
        // 推导链（按 .trellis/tasks/07-27-daliuren-sanchuan-fix/design.md 手工复核）：
        // 2026-04-18 22:20 → 日柱壬戌，月将戌（由太阳过宫自动推得），时支亥。
        // 天盘：戌加临亥，位移 s=+11（天盘支=地盘支+11）。
        // 四课（壬寄亥，新旧寄宫表同为亥，本例四课不受寄宫表修正影响）：
        //   一课 戌/壬（戌土克壬水，上克下）；二课 酉/戌（下生上）；
        //   三课 酉/戌（下生上）；四课 申/酉（比和）。
        // 课体：无下贼上、仅一课上克下 → 贼克（元首课），初传取上神戌；
        // 中传=天盘[戌]=酉，末传=天盘[酉]=申 → 三传 戌酉申。
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

      test('时间起课只保存白名单参数并深复制 caller input', () async {
        final castTime = DateTime.utc(2026, 4, 18, 14, 20);
        final params = <String, dynamic>{'dayNightMode': 'day'};
        final input = <String, dynamic>{
          'sourceUtcOffsetMinutes': 480,
          'question': '不得进入结果快照',
          'extra': <String, dynamic>{'private': true},
          'params': params,
        };

        final result = await system.cast(
          method: CastMethod.time,
          input: input,
          castTime: castTime,
        ) as DaLiuRenResult;
        params['dayNightMode'] = 'night';
        input['lateMutation'] = true;

        final snapshot = result.castInputSnapshot!;
        final savedParams =
            snapshot.normalizedInput['params'] as Map<String, dynamic>;
        expect(result.panRuleSetVersion, DlrRuleSetVersions.panCurrent);
        expect(
          result.evidenceCatalogVersion,
          DlrRuleSetVersions.evidenceCatalog,
        );
        expect(snapshot.castMethod, CastMethod.time);
        expect(snapshot.schemaVersion, DlrRuleSetVersions.castInputSchema);
        expect(snapshot.castTime, castTime.toUtc());
        expect(snapshot.utcOffsetMinutes, 480);
        expect(snapshot.replayStatus, DlrReplayStatus.complete);
        expect(snapshot.missingFields, isEmpty);
        expect(savedParams['dayNightMode'], 'day');
        expect(
          snapshot.normalizedInput['civilTime'],
          result.civilTime!.toJson(),
        );
        expect(
          snapshot.normalizedInput.keys,
          unorderedEquals(<String>['civilTime', 'params']),
        );
        expect(result.monthGeneralResolution, isNotNull);
      });

      test('同一绝对时刻的三种自动入口共享月将且只覆盖时柱', () async {
        final instant = DateTime.utc(2022, 4, 20, 2, 24, 18);
        final timeResult = await system.cast(
          method: CastMethod.time,
          input: const <String, dynamic>{'sourceUtcOffsetMinutes': 480},
          castTime: instant,
        ) as DaLiuRenResult;
        final reportResult = await system.cast(
          method: CastMethod.reportNumber,
          input: const <String, dynamic>{
            'number': 1,
            'sourceUtcOffsetMinutes': 480,
          },
          castTime: instant,
        ) as DaLiuRenResult;
        final computerResult = await system.cast(
          method: CastMethod.computer,
          input: const <String, dynamic>{'sourceUtcOffsetMinutes': 480},
          castTime: instant,
        ) as DaLiuRenResult;

        expect(
          <String>{
            timeResult.tianPan.yueJiang,
            reportResult.tianPan.yueJiang,
            computerResult.tianPan.yueJiang,
          },
          <String>{'酉'},
        );
        expect(
          <String?>{
            timeResult.monthGeneralResolution!.effectiveZhongQi,
            reportResult.monthGeneralResolution!.effectiveZhongQi,
            computerResult.monthGeneralResolution!.effectiveZhongQi,
          },
          <String?>{'谷雨'},
        );
        expect(reportResult.tianPan.shiZhi, '子');
        expect(
          reportResult.lunarInfo.hourGanZhi,
          '${DlrPillars.expectedHourGanFor(dayGan: reportResult.lunarInfo.riGan, hourZhi: '子')}子',
        );
        expect(
            reportResult.lunarInfo.yearGanZhi, timeResult.lunarInfo.yearGanZhi);
        expect(reportResult.lunarInfo.monthGanZhi,
            timeResult.lunarInfo.monthGanZhi);
        expect(reportResult.lunarInfo.riGanZhi, timeResult.lunarInfo.riGanZhi);
      });

      test('显式来源 offset 被一次捕获且不会改变同一 instant 的月将', () async {
        final instant = DateTime.utc(2022, 4, 20, 2, 24, 18);
        final results = <DaLiuRenResult>[];
        for (final offset in <int>[480, 330, 0]) {
          results.add(
            await system.cast(
              method: CastMethod.time,
              input: <String, dynamic>{'sourceUtcOffsetMinutes': offset},
              castTime: instant,
            ) as DaLiuRenResult,
          );
        }

        expect(
          results.map((result) => result.tianPan.yueJiang).toSet(),
          <String>{'酉'},
        );
        expect(
          results.map((result) => result.civilTime!.sourceUtcOffsetMinutes),
          <int>[480, 330, 0],
        );
        expect(
          results.map((result) => result.castInputSnapshot!.utcOffsetMinutes),
          <int>[480, 330, 0],
        );
      });

      test('报数起课保存原数与实际解析时支、时柱', () async {
        final result = await system.cast(
          method: CastMethod.reportNumber,
          input: const <String, dynamic>{
            'number': 13,
            'question': '不得进入结果快照',
          },
          castTime: DateTime(2026, 4, 18, 22, 20),
        ) as DaLiuRenResult;

        final snapshot = result.castInputSnapshot!;
        expect(snapshot.castMethod, CastMethod.reportNumber);
        expect(snapshot.replayStatus, DlrReplayStatus.complete);
        expect(snapshot.normalizedInput['number'], 13);
        expect(snapshot.normalizedInput['resolvedShiZhi'], '子');
        expect(
          snapshot.normalizedInput['resolvedHourGanZhi'],
          result.lunarInfo.hourGanZhi,
        );
        expect(snapshot.normalizedInput, isNot(contains('question')));
      });

      test('电脑起课保存实际解析值但未消费 seed 时保持 incomplete', () async {
        final result = await system.cast(
          method: CastMethod.computer,
          input: const <String, dynamic>{
            'randomSeed': 42,
            'question': '不得进入结果快照',
          },
          castTime: DateTime(2026, 4, 18, 22, 20),
        ) as DaLiuRenResult;

        final snapshot = result.castInputSnapshot!;
        expect(snapshot.castMethod, CastMethod.computer);
        expect(snapshot.replayStatus, DlrReplayStatus.incomplete);
        expect(snapshot.missingFields, <String>['randomSeed']);
        expect(
          snapshot.normalizedInput['resolvedShiZhi'],
          result.tianPan.shiZhi,
        );
        expect(
          snapshot.normalizedInput['resolvedHourGanZhi'],
          result.lunarInfo.hourGanZhi,
        );
        expect(snapshot.normalizedInput, isNot(contains('randomSeed')));
        expect(snapshot.normalizedInput, isNot(contains('question')));
      });

      test('手动四柱显式月将可完整重放', () async {
        final result = await system.cast(
          method: CastMethod.manual,
          input: const <String, dynamic>{
            'manualInputMode': 'rawPillars',
            'yearGanZhi': '丙午',
            'monthGanZhi': '壬辰',
            'dayGanZhi': '壬戌',
            'hourGanZhi': '辛亥',
            'question': '不得进入结果快照',
            'params': <String, dynamic>{
              'monthGeneralMode': 'manual',
              'manualMonthGeneral': '戌',
            },
          },
          castTime: DateTime(2026, 4, 18, 22, 20),
        ) as DaLiuRenResult;

        final snapshot = result.castInputSnapshot!;
        expect(snapshot.castMethod, CastMethod.manual);
        expect(snapshot.replayStatus, DlrReplayStatus.complete);
        expect(snapshot.missingFields, isEmpty);
        expect(snapshot.normalizedInput['manualInputMode'], 'rawPillars');
        expect(snapshot.normalizedInput['calendarValidated'], isFalse);
        expect(snapshot.normalizedInput['yearGanZhi'], '丙午');
        expect(snapshot.normalizedInput['monthGanZhi'], '壬辰');
        expect(snapshot.normalizedInput['dayGanZhi'], '壬戌');
        expect(snapshot.normalizedInput['hourGanZhi'], '辛亥');
        expect(snapshot.normalizedInput, isNot(contains('question')));
        expect(result.civilTime, isNull);
        expect(
          result.monthGeneralResolution!.mode,
          DlrMonthGeneralResolutionMode.manualOverride,
        );
        expect(result.lunarInfo.solarTerm, isNull);
      });

      test('rawPillars 不读取操作时刻派生四柱或月将', () async {
        const input = <String, dynamic>{
          'manualInputMode': 'rawPillars',
          'yearGanZhi': '丙午',
          'monthGanZhi': '壬辰',
          'dayGanZhi': '壬戌',
          'hourGanZhi': '辛亥',
          'params': <String, dynamic>{
            'monthGeneralMode': 'manual',
            'manualMonthGeneral': '戌',
          },
        };
        final first = await system.cast(
          method: CastMethod.manual,
          input: input,
          castTime: DateTime.utc(2022, 4, 20, 2, 24, 17),
        ) as DaLiuRenResult;
        final second = await system.cast(
          method: CastMethod.manual,
          input: input,
          castTime: DateTime.utc(2035, 12, 22, 0),
        ) as DaLiuRenResult;

        expect(second.lunarInfo, first.lunarInfo);
        expect(second.tianPan, first.tianPan);
        expect(second.siKe, first.siKe);
        expect(second.sanChuan, first.sanChuan);
        expect(second.monthGeneralResolution, first.monthGeneralResolution);
        expect(first.castInputSnapshot!.castTime,
            DateTime.utc(2022, 4, 20, 2, 24, 17));
        expect(
            second.castInputSnapshot!.castTime, DateTime.utc(2035, 12, 22, 0));
      });

      test('calendarBacked 校验四柱并以民用 instant 构建完整事实', () async {
        final operationTime = DateTime.utc(2030, 1, 1);
        final civilInstant = DateTime.utc(2026, 4, 18, 14, 20);
        final result = await system.cast(
          method: CastMethod.manual,
          input: <String, dynamic>{
            'manualInputMode': 'calendarBacked',
            'manualCivilDateTime': civilInstant,
            'sourceUtcOffsetMinutes': 480,
            'yearGanZhi': '丙午',
            'monthGanZhi': '壬辰',
            'dayGanZhi': '壬戌',
            'hourGanZhi': '辛亥',
          },
          castTime: operationTime,
        ) as DaLiuRenResult;

        final snapshot = result.castInputSnapshot!;
        expect(result.castTime, operationTime);
        expect(result.civilTime!.instantUtc, civilInstant);
        expect(result.civilTime!.sourceUtcOffsetMinutes, 480);
        expect(result.tianPan.yueJiang, '戌');
        expect(
          result.monthGeneralResolution!.mode,
          DlrMonthGeneralResolutionMode.zhongQi,
        );
        expect(snapshot.castTime, civilInstant);
        expect(snapshot.utcOffsetMinutes, 480);
        expect(snapshot.replayStatus, DlrReplayStatus.complete);
        expect(snapshot.missingFields, isEmpty);
        expect(snapshot.normalizedInput['manualInputMode'], 'calendarBacked');
        expect(snapshot.normalizedInput['calendarValidated'], isTrue);
        expect(snapshot.normalizedInput['manualCivilDateTime'],
            civilInstant.toIso8601String());
      });

      test('手工模式必须显式完整且 calendarBacked 柱不符时指出字段', () async {
        const implicitMode = <String, dynamic>{
          'yearGanZhi': '丙午',
          'monthGanZhi': '壬辰',
          'dayGanZhi': '壬戌',
          'hourGanZhi': '辛亥',
          'params': <String, dynamic>{
            'monthGeneralMode': 'manual',
            'manualMonthGeneral': '戌',
          },
        };
        const rawWithoutGeneral = <String, dynamic>{
          'manualInputMode': 'rawPillars',
          'yearGanZhi': '丙午',
          'monthGanZhi': '壬辰',
          'dayGanZhi': '壬戌',
          'hourGanZhi': '辛亥',
        };
        final mismatch = <String, dynamic>{
          'manualInputMode': 'calendarBacked',
          'manualCivilDateTime': DateTime.utc(2026, 4, 18, 14, 20),
          'sourceUtcOffsetMinutes': 480,
          'yearGanZhi': '丙午',
          'monthGanZhi': '壬辰',
          'dayGanZhi': '壬戌',
          'hourGanZhi': '庚戌',
        };

        expect(system.validateInput(CastMethod.manual, implicitMode), isFalse);
        expect(
          system.validateInput(CastMethod.manual, rawWithoutGeneral),
          isFalse,
        );
        expect(system.validateInput(CastMethod.manual, mismatch), isFalse);
        await expectLater(
          system.cast(method: CastMethod.manual, input: mismatch),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message.toString(),
              'message',
              contains('hourGanZhi'),
            ),
          ),
        );
      });

      test('rawPillars 拒绝年月或日时干联动错误', () async {
        Map<String, dynamic> input({
          String monthGanZhi = '壬辰',
          String hourGanZhi = '辛亥',
        }) =>
            <String, dynamic>{
              'manualInputMode': 'rawPillars',
              'yearGanZhi': '丙午',
              'monthGanZhi': monthGanZhi,
              'dayGanZhi': '壬戌',
              'hourGanZhi': hourGanZhi,
              'params': const <String, dynamic>{
                'monthGeneralMode': 'manual',
                'manualMonthGeneral': '戌',
              },
            };

        for (final invalid in <Map<String, dynamic>>[
          input(monthGanZhi: '庚辰'),
          input(hourGanZhi: '己亥'),
        ]) {
          expect(system.validateInput(CastMethod.manual, invalid), isFalse);
          await expectLater(
            system.cast(method: CastMethod.manual, input: invalid),
            throwsArgumentError,
          );
        }
      });

      test('calendarBacked 缺显式 civil instant 或 offset 时直接无效', () {
        final base = <String, dynamic>{
          'manualInputMode': 'calendarBacked',
          'manualCivilDateTime': DateTime.utc(2026, 4, 18, 14, 20),
          'sourceUtcOffsetMinutes': 480,
          'yearGanZhi': '丙午',
          'monthGanZhi': '壬辰',
          'dayGanZhi': '壬戌',
          'hourGanZhi': '辛亥',
        };
        final noInstant = Map<String, dynamic>.from(base)
          ..remove('manualCivilDateTime');
        final noOffset = Map<String, dynamic>.from(base)
          ..remove('sourceUtcOffsetMinutes');

        expect(system.validateInput(CastMethod.manual, noInstant), isFalse);
        expect(system.validateInput(CastMethod.manual, noOffset), isFalse);
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
