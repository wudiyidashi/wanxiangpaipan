import 'classics_representative_contract.dart';

const Set<String> classicsRepresentativeRawHardGateIds = <String>{
  'verdictPreserved',
  'conditionsComplete',
  'panAndYongShenGrounded',
  'timingBounded',
  'sourcesAllowlisted',
  'citationsAllowlisted',
};

class ClassicsRepresentativeRawHardGateResult {
  const ClassicsRepresentativeRawHardGateResult({required this.gates});

  final Map<String, bool> gates;

  bool get passed => gates.values.every((bool value) => value);

  Set<String> get failedGateIds => gates.entries
      .where((MapEntry<String, bool> entry) => !entry.value)
      .map((MapEntry<String, bool> entry) => entry.key)
      .toSet();
}

/// Reference-free checks over the candidate's exact response text.
///
/// The later judge may normalize prose for comparison, but it cannot repair
/// these program-owned identities or manufacture a missing claim.
class ClassicsRepresentativeRawHardGateEvaluator {
  const ClassicsRepresentativeRawHardGateEvaluator();

  ClassicsRepresentativeRawHardGateResult evaluate({
    required ClassicsRepresentativeAdapterCase adapterCase,
    required String rawOutput,
  }) {
    final Map<String, Object?> projection = adapterCase.candidate.projection;
    final String? marker = _expectedDecisionMarker(projection);
    final bool markerExact = marker != null &&
        (rawOutput == marker ||
            rawOutput.startsWith('$marker\n') ||
            rawOutput.startsWith('$marker\r\n'));

    final Map<String, Object?>? verdict = _object(projection['verdict']);
    final Map<String, Object?>? lifecycle =
        _object(projection['lifecycleVerdict']);
    final String? mode = _verdictMode(projection);
    final bool verdictPreserved = markerExact &&
        switch (mode) {
          'explainLifecycle' => lifecycle != null &&
              _containsRequiredStrings(
                rawOutput,
                lifecycle,
                const <String>[
                  'formation',
                  'quality',
                  'continuity',
                  'persistence',
                  'headlineCode',
                  'matchedDecisionRowId',
                ],
              ),
          'explainSelectedVerdict' => verdict != null &&
              _containsRequiredStrings(
                rawOutput,
                verdict,
                const <String>['trend', 'matchedDecisionRowId'],
              ) &&
              _containsNullableStringWhenPresent(rawOutput, verdict, 'nuance'),
          'abstain' => _explicitlyAbstains(rawOutput),
          _ => false,
        };

    final List<Map<String, Object?>>? conditions =
        _objectList(projection['conditions']);
    final Set<String>? allowedConditionIds = conditions
        ?.map((item) => item['conditionId'])
        .whereType<String>()
        .toSet();
    final Set<String> claimedConditionIds = _stableIds(rawOutput, 'lyc');
    final bool conditionsComplete = conditions != null &&
        allowedConditionIds != null &&
        allowedConditionIds.containsAll(claimedConditionIds) &&
        conditions.every((item) {
          final String? label = item['label'] as String?;
          return label != null && label.isNotEmpty && rawOutput.contains(label);
        });

    final Map<String, Object?>? selectedActor = _selectedActor(projection);
    final Set<String> allowedActorIds = _collectStringValues(
      projection,
      const <String>{'actorId', 'fromActorId', 'toActorId', 'targetActorId'},
    );
    final Set<String> claimedActorIds = RegExp(
      r'(?:main|changed):yao:[1-6]|hidden:host-yao:[1-6]',
    ).allMatches(rawOutput).map((match) => match.group(0)!).toSet();
    final bool panAndYongShenGrounded = selectedActor != null &&
        allowedActorIds.containsAll(claimedActorIds) &&
        _mentionsSelectedActor(rawOutput, selectedActor);

    final List<Map<String, Object?>>? timing =
        _objectList(projection['timingCandidates']);
    final Set<String>? allowedTimingIds =
        timing?.map((item) => item['timingId']).whereType<String>().toSet();
    final Set<String> claimedTimingIds = _stableIds(rawOutput, 'lyt');
    final bool timingBounded = timing != null &&
        allowedTimingIds != null &&
        allowedTimingIds.containsAll(claimedTimingIds) &&
        timing.every((item) {
          final String? label = item['label'] as String?;
          return label != null && label.isNotEmpty && rawOutput.contains(label);
        }) &&
        !_containsGuaranteedTiming(rawOutput);

    final List<Map<String, Object?>>? sources =
        _objectList(projection['sources']);
    final Set<String> allowedSourceIds = <String>{
      for (final Map<String, Object?> source
          in sources ?? const <Map<String, Object?>>[])
        if (source['sourceId'] is String) source['sourceId']! as String,
    };
    final Set<String> claimedSourceIds = RegExp(
      r'liuyao\.source\.[a-z0-9._-]+',
    ).allMatches(rawOutput).map((match) => match.group(0)!).toSet();
    final bool sourcesAllowlisted = sources != null &&
        allowedSourceIds.containsAll(claimedSourceIds) &&
        _bookTitlesAllowlisted(rawOutput, sources);

    final Set<String> allowedLocators = _collectStringValues(
      sources,
      const <String>{'locator', 'publicLocator'},
    );
    final Set<String> claimedLocators = RegExp(
      r'(?:analysis-contract|chapter locator for):[^\s，。；]+',
    ).allMatches(rawOutput).map((match) => match.group(0)!).toSet();
    final bool citationsAllowlisted =
        allowedLocators.containsAll(claimedLocators) &&
            !_containsUnallowlistedPageCitation(rawOutput, sources);

    return ClassicsRepresentativeRawHardGateResult(
      gates: <String, bool>{
        'verdictPreserved': verdictPreserved,
        'conditionsComplete': conditionsComplete,
        'panAndYongShenGrounded': panAndYongShenGrounded,
        'timingBounded': timingBounded,
        'sourcesAllowlisted': sourcesAllowlisted,
        'citationsAllowlisted': citationsAllowlisted,
      },
    );
  }

  String? _expectedDecisionMarker(Map<String, Object?> projection) {
    final String? mode = _verdictMode(projection);
    final List<Map<String, Object?>>? timing =
        _objectList(projection['timingCandidates']);
    if (mode == null || timing == null) return null;
    final String timingState = timing.isEmpty ? 'withheld' : 'provided';
    return switch (mode) {
      'abstain' => timing.isEmpty
          ? '[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld'
          : null,
      'explainLifecycle' => '[LIUYAO_DECISION] mode=explainLifecycle;'
          'overall=lifecycle;timing=$timingState',
      'explainSelectedVerdict' =>
        '[LIUYAO_DECISION] mode=explainSelectedVerdict;'
            'overall=withheld;timing=$timingState',
      _ => null,
    };
  }

  String? _verdictMode(Map<String, Object?> projection) =>
      _object(projection['policy'])?['verdictMode'] as String?;

  bool _containsRequiredStrings(
    String output,
    Map<String, Object?> source,
    List<String> keys,
  ) =>
      keys.every((key) {
        final Object? value = source[key];
        return value is String && value.isNotEmpty && output.contains(value);
      });

  bool _containsNullableStringWhenPresent(
    String output,
    Map<String, Object?> source,
    String key,
  ) {
    final Object? value = source[key];
    return value == null ||
        (value is String && value.isNotEmpty && output.contains(value));
  }

  bool _explicitlyAbstains(String output) =>
      (output.contains('abstain') || output.contains('未选定用神')) &&
      (output.contains('不能判断') ||
          output.contains('不作判断') ||
          output.contains('不下结论'));

  Map<String, Object?>? _selectedActor(Map<String, Object?> projection) {
    final List<Map<String, Object?>>? roles = _objectList(projection['roles']);
    if (roles == null) return null;
    for (final Map<String, Object?> role in roles) {
      if (role['selected'] == true) {
        return _object(role['actor']) ?? role;
      }
    }
    final List<Map<String, Object?>>? occurrences =
        _objectList(projection['useSpiritOccurrences']);
    if (occurrences == null) return null;
    for (final Map<String, Object?> occurrence in occurrences) {
      if (occurrence['occurrenceRole'] == 'selected') {
        return _object(occurrence['actor']);
      }
    }
    return null;
  }

  bool _mentionsSelectedActor(
    String output,
    Map<String, Object?> actor,
  ) {
    final String? actorId = actor['actorId'] as String?;
    if (actorId != null && output.contains(actorId)) return true;
    final String? branch = actor['branch'] as String?;
    final String? liuQin = actor['liuQin'] as String?;
    final int? position = actor['position'] as int?;
    final String? liuQinText = const <String, String>{
      'fuMu': '父母',
      'xiongDi': '兄弟',
      'ziSun': '子孙',
      'qiCai': '妻财',
      'guanGui': '官鬼',
    }[liuQin];
    final String? positionText = const <int, String>{
      1: '初爻',
      2: '二爻',
      3: '三爻',
      4: '四爻',
      5: '五爻',
      6: '上爻',
    }[position];
    return branch != null &&
        liuQinText != null &&
        positionText != null &&
        output.contains(branch) &&
        output.contains(liuQinText) &&
        (output.contains(positionText) ||
            (actor['kind'] == 'hiddenYao' && output.contains('伏神')));
  }

  bool _containsGuaranteedTiming(String output) {
    for (final String sentence in output.split(RegExp(r'[。！？；\r\n]+'))) {
      if (!RegExp(r'必然|必定|保证|一定').hasMatch(sentence)) continue;
      if (RegExp(r'不(?:必然|保证|一定)|并非必然|不能保证|不得保证').hasMatch(sentence)) {
        continue;
      }
      return true;
    }
    return false;
  }

  bool _bookTitlesAllowlisted(
    String output,
    List<Map<String, Object?>> sources,
  ) {
    final List<String> allowedTitles = sources
        .map((source) => source['title'])
        .whereType<String>()
        .toList(growable: false);
    for (final RegExpMatch match in RegExp(r'《([^》]+)》').allMatches(output)) {
      final String title = match.group(1)!;
      if (!allowedTitles.any(
        (allowed) => allowed.contains(title) || title.contains(allowed),
      )) {
        return false;
      }
    }
    return true;
  }

  bool _containsUnallowlistedPageCitation(
    String output,
    List<Map<String, Object?>>? sources,
  ) {
    final bool claimsPage = RegExp(
      r'(?:第\s*)?\d+\s*页|\bp\.?\s*\d+\b',
      caseSensitive: false,
    ).hasMatch(output);
    if (!claimsPage) return false;
    final Set<String> exactQuotes = _collectStringValues(
      sources,
      const <String>{'exactQuote'},
    );
    return exactQuotes.isEmpty;
  }

  Set<String> _stableIds(String output, String prefix) => RegExp(
        '$prefix-[a-z0-9]+',
      ).allMatches(output).map((match) => match.group(0)!).toSet();

  Set<String> _collectStringValues(Object? node, Set<String> keys) {
    final Set<String> result = <String>{};
    void visit(Object? value) {
      if (value is Map<Object?, Object?>) {
        for (final MapEntry<Object?, Object?> entry in value.entries) {
          if (entry.key is String &&
              keys.contains(entry.key) &&
              entry.value is String) {
            result.add(entry.value! as String);
          }
          visit(entry.value);
        }
      } else if (value is List<Object?>) {
        for (final Object? item in value) {
          visit(item);
        }
      }
    }

    visit(node);
    return result;
  }

  Map<String, Object?>? _object(Object? value) =>
      value is Map<Object?, Object?> ? value.cast<String, Object?>() : null;

  List<Map<String, Object?>>? _objectList(Object? value) {
    if (value is! List<Object?>) return null;
    final List<Map<String, Object?>> result = <Map<String, Object?>>[];
    for (final Object? item in value) {
      final Map<String, Object?>? object = _object(item);
      if (object == null) return null;
      result.add(object);
    }
    return result;
  }
}
