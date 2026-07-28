import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

import '../../services/qimen/fixtures/qimen_golden_fixtures.dart';

void main() {
  group('QimenSystem contract', () {
    final system = QimenSystem();

    test('is enabled with stable product and method IDs', () {
      expect(system.type, DivinationType.qiMen);
      expect(system.type.id, 'qimen');
      expect(system.isEnabled, true);
      expect(system.supportedMethods, [CastMethod.time, CastMethod.manual]);
      expect(system.supportedMethods.map((method) => method.id), [
        'time',
        'manual',
      ]);
    });

    test('time accepts omitted params and rejects malformed params', () {
      expect(system.validateInput(CastMethod.time, const {}), true);
      expect(
        system.validateInput(
          CastMethod.time,
          const {'unexpected': true},
        ),
        false,
      );
      expect(
        system.validateInput(
          CastMethod.time,
          const {
            'params': {'unexpected': true}
          },
        ),
        false,
      );
      expect(
        system.validateInput(
          CastMethod.time,
          const {
            'params': {'juMethod': 'unknown'}
          },
        ),
        false,
      );
      for (final longitude in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          system.validateInput(
            CastMethod.time,
            {
              'params': {
                'timeBasis': 'trueSolar',
                'sourceUtcOffsetMinutes': 480,
                'longitude': longitude,
              },
            },
          ),
          false,
        );
      }
      expect(
        system.validateInput(
          CastMethod.time,
          const {
            'params': {
              'timeBasis': 'trueSolar',
              'sourceUtcOffsetMinutes': 480,
              'longitude': 181,
            },
          },
        ),
        false,
      );
    });

    test('manual requires complete explicit pillars and ju facts', () {
      expect(system.validateInput(CastMethod.manual, qimenManualGoldenInput),
          true);
      expect(
        system.validateInput(
          CastMethod.manual,
          <String, dynamic>{
            ...qimenManualGoldenInput,
            'unexpected': true,
          },
        ),
        false,
      );
      final manualWithJuMethod = <String, dynamic>{
        ...qimenManualGoldenInput,
        'params': <String, dynamic>{
          ...Map<String, dynamic>.from(
            qimenManualGoldenInput['params'] as Map,
          ),
          'juMethod': 'chaiBu',
        },
      };
      expect(
        system.validateInput(CastMethod.manual, manualWithJuMethod),
        false,
      );
      final missingHour = Map<String, dynamic>.from(qimenManualGoldenInput)
        ..remove('hourGanZhi');
      expect(system.validateInput(CastMethod.manual, missingHour), false);
      expect(
        system.validateInput(
          CastMethod.manual,
          {...qimenManualGoldenInput, 'dayGanZhi': '甲丑'},
        ),
        false,
      );
    });

    test('result JSON is strict, stable-ID based, and deeply reversible',
        () async {
      final original = await system.cast(
        method: CastMethod.manual,
        input: qimenManualGoldenInput,
        castTime: DateTime.utc(2026, 7, 7, 4),
      ) as QimenResult;
      final json = original.toJson();
      final restored = system.resultFromJson(json) as QimenResult;

      expect(json['schemaVersion'], 1);
      expect(json['systemType'], 'qimen');
      expect(json['castMethod'], 'manual');
      expect(json['panParams']['hostingMode'], 'kunTwo');
      expect(restored.toJson(), json);
      expect(restored.getSummary(), original.getSummary());

      expect(
        () => system.resultFromJson({...json, 'schemaVersion': 2}),
        throwsFormatException,
      );
      expect(
        () => system.resultFromJson({...json, 'systemType': 'liuyao'}),
        throwsFormatException,
      );
    });

    test('serializes absolute cast instants in UTC', () async {
      final localCastTime = DateTime(2026, 7, 7, 12, 34, 56);
      final result = await system.cast(
        method: CastMethod.manual,
        input: qimenManualGoldenInput,
        castTime: localCastTime,
      ) as QimenResult;
      final json = result.toJson();
      final temporal = json['temporalContext'] as Map<String, dynamic>;
      final expected = localCastTime.toUtc().toIso8601String();

      expect(json['castTime'], expected);
      expect(temporal['originalTime'], expected);
      expect((json['castTime'] as String).endsWith('Z'), true);
      expect((temporal['originalTime'] as String).endsWith('Z'), true);

      final restored = system.resultFromJson(json) as QimenResult;
      expect(restored.castTime.isUtc, true);
      expect(restored.temporalContext.originalTime.isUtc, true);
      expect(restored.toJson(), json);
    });

    test('all automatic methods persist a complete derivation header',
        () async {
      for (final method in <String>['chaiBu', 'maoShan', 'zhiRun']) {
        final result = await system.cast(
          method: CastMethod.time,
          input: <String, dynamic>{
            'params': <String, dynamic>{
              'juMethod': method,
              'timeBasis': 'beijing',
              'sourceUtcOffsetMinutes': 480,
            },
          },
          castTime: DateTime.utc(2025, 6, 8, 4),
        ) as QimenResult;
        final header = result.derivationSteps.take(3).join('\n');

        expect(header, contains('生效排盘时间'), reason: method);
        expect(header, contains('交节时刻'), reason: method);
        expect(header, contains('定局法$method'), reason: method);
        expect(header, contains(result.juInfo.effectiveSolarTerm),
            reason: method);
        expect(header, contains(result.juInfo.yuan.label), reason: method);
        expect(header, contains('${result.juInfo.dun.label}遁'), reason: method);
        expect(header, contains('${result.juInfo.juNumber}局'), reason: method);
        expect(header, contains('符头'), reason: method);
        expect(header, contains('置闰'), reason: method);
      }
    });
  });
}
