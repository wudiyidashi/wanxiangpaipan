import '../../../domain/services/liuyao/analysis/rules/liuyao_catalog.dart';

/// Builds the deterministic, de-duplicated Liuyao projection sent to the LLM.
///
/// The full schema-2 projection remains the program-owned source of truth in
/// section metadata. This view keeps decision-bearing facts while replacing
/// repeated embedded objects with stable occurrence/actor references.
class LiuYaoAiProjectionCompactor {
  const LiuYaoAiProjectionCompactor._();

  static const int schemaVersion = 1;
  static const String _bindingOpenedRuleId = LiuYaoRuleIds.ruleBindingOpened;
  static const String _mutualBindingRuleId = LiuYaoRuleIds.ruleMutualBinding;
  static const String _openedBindingAvailabilityRuleId =
      LiuYaoRuleIds.actorBindingOpened;
  static const String _apparentVoidRuleId = LiuYaoRuleIds.ruleApparentVoid;
  static const String _changedVoidRuleId = LiuYaoRuleIds.ruleChangedVoid;
  static const String _tombOpenedRuleId = LiuYaoRuleIds.ruleTombOpened;
  static const Object _omitted = Object();

  static Map<String, Object?> compact(Map<String, Object?> projection) {
    if (_required(projection, 'projectionSchemaVersion') != 2) {
      throw StateError('Liuyao AI projection requires full schema 2');
    }

    final conditions = _requiredList(projection, 'conditions');
    final timingCandidates = _requiredList(projection, 'timingCandidates');
    final currentStateOnly = conditions.isEmpty && timingCandidates.isEmpty;
    // With no projected release chain, resolved binding facts stay available
    // to the program in the untouched full projection and stay out of the LLM
    // view entirely.
    final omittedOccurrenceIds = currentStateOnly
        ? _collectResolvedBindingOccurrenceIds(
            _requiredList(projection, 'actorFacts'),
          )
        : const <String>{};
    final omittedRuleIds = currentStateOnly
        ? const <String>{
            _bindingOpenedRuleId,
            _openedBindingAvailabilityRuleId,
          }
        : const <String>{};

    final actorFacts = _requiredList(projection, 'actorFacts')
        .map(
          (fact) => _compactActorFact(
            fact,
            currentStateOnly: currentStateOnly,
          ),
        )
        .toList(growable: false);
    final directedEffects = _requiredList(projection, 'directedEffects')
        .map(_compactEffect)
        .toList(growable: false);
    final auxiliaryEvidence = _requiredList(projection, 'auxiliaryEvidence')
        .map(
          (tag) => _compactTag(
            tag,
            currentStateOnly: currentStateOnly,
          ),
        )
        .toList(growable: false);
    final conflicts = _required(projection, 'conflicts');
    final selectedFacts = _requiredList(projection, 'selectedUseSpiritFacts');
    final selectedFactOccurrenceIds = selectedFacts
        .map((tag) =>
            _required(_object(tag, 'selectedUseSpiritFacts[]'), 'occurrenceId'))
        .toList(growable: false);
    final alreadyProjectedOccurrenceIds = _collectOccurrenceIds(<Object?>[
      actorFacts,
      directedEffects,
      auxiliaryEvidence,
      conflicts,
    ]);
    final supplementalSelectedFacts = selectedFacts
        .where((tag) => !alreadyProjectedOccurrenceIds.contains(
              _required(
                _object(tag, 'selectedUseSpiritFacts[]'),
                'occurrenceId',
              ),
            ))
        .map(
          (tag) => _compactTag(
            tag,
            currentStateOnly: currentStateOnly,
          ),
        )
        .toList(growable: false);

    final compact = <String, Object?>{
      'aiProjectionSchemaVersion': schemaVersion,
      'projectionView': 'aiCompact',
      'fullProjectionAvailableToProgram': true,
      'analysisSchemaVersion': _required(projection, 'analysisSchemaVersion'),
      'projectionSchemaVersion':
          _required(projection, 'projectionSchemaVersion'),
      'ruleSetId': _required(projection, 'ruleSetId'),
      'ruleSetVersion': _required(projection, 'ruleSetVersion'),
      'sourceCatalogVersion': _required(projection, 'sourceCatalogVersion'),
      'status': _required(projection, 'status'),
      'pan': _required(projection, 'pan'),
      'policy': _required(projection, 'policy'),
      'questionFocus': _required(projection, 'questionFocus'),
      'useSpirit': _required(projection, 'useSpirit'),
      'verdict': _compactVerdict(
        _required(projection, 'verdict'),
        currentStateOnly: currentStateOnly,
      ),
      'lifecycleVerdict': _required(projection, 'lifecycleVerdict'),
      'actorFacts': actorFacts,
      'useSpiritOccurrences': _requiredList(projection, 'useSpiritOccurrences')
          .map(
            (occurrence) => _compactUseSpiritOccurrence(
              occurrence,
              currentStateOnly: currentStateOnly,
            ),
          )
          .toList(growable: false),
      'selectedUseSpiritFacts': <String, Object?>{
        'selectedFactOccurrenceIds': selectedFactOccurrenceIds,
        // Selected-axis analysis can contain records intentionally absent from
        // actorFacts, or actor-scoped copies with different occurrence IDs.
        'factsNotPresentElsewhere': supplementalSelectedFacts,
      },
      'roles': _requiredList(projection, 'roles')
          .map(_compactRole)
          .toList(growable: false),
      'shiYingRelation': _required(projection, 'shiYingRelation'),
      'directedEffects': directedEffects,
      'factors': _required(projection, 'factors'),
      'conditions': conditions,
      'timingCandidates': timingCandidates,
      'auxiliaryEvidence': auxiliaryEvidence,
      'interpretiveEvidence': _required(projection, 'interpretiveEvidence'),
      'conflicts': conflicts,
      'diagnostics': _required(projection, 'diagnostics'),
      'omittedAsDuplicateOrProgramOnly': const <String>[
        'actorAvailability',
        'analysisStages',
        'trace',
        'unreferencedSourceReferences',
      ],
    };
    final pruned = _omitEvidence(
      compact,
      occurrenceIds: omittedOccurrenceIds,
      ruleIds: omittedRuleIds,
    );
    if (pruned is! Map<String, Object?>) {
      throw StateError('Liuyao AI compact projection root was omitted');
    }
    // Actor records stay complete, but their every background state rule does
    // not need a second copy of the classical locator. Keep source references
    // for the chains the model is actually allowed to cite in its answer.
    final explanationBranches = <Object?>[
      pruned['questionFocus'],
      pruned['useSpirit'],
      pruned['verdict'],
      pruned['lifecycleVerdict'],
      pruned['selectedUseSpiritFacts'],
      pruned['useSpiritOccurrences'],
      pruned['roles'],
      pruned['shiYingRelation'],
      pruned['directedEffects'],
      pruned['factors'],
      pruned['conditions'],
      pruned['timingCandidates'],
      pruned['auxiliaryEvidence'],
      pruned['interpretiveEvidence'],
      pruned['conflicts'],
    ];
    final citedRuleIds = _collectRuleIds(explanationBranches);
    final ruleIdByOccurrenceId = _indexOccurrenceRuleIds(projection);
    for (final occurrenceId
        in _collectReferencedOccurrenceIds(explanationBranches)) {
      final ruleId = ruleIdByOccurrenceId[occurrenceId];
      if (ruleId != null) citedRuleIds.add(ruleId);
    }
    citedRuleIds.removeAll(omittedRuleIds);
    pruned['sources'] = _requiredList(projection, 'sources')
        .map((source) => _compactSource(source, citedRuleIds))
        .toList(growable: false);
    // Several retained branches are intentionally copied wholesale from the
    // validated domain projection. Detach them so consumers of the model view
    // cannot mutate the full schema-2 metadata through shared maps or lists.
    return _copyJson(pruned, 'projection') as Map<String, Object?>;
  }

  static Map<String, Object?> _compactActorFact(
    Object? raw, {
    required bool currentStateOnly,
  }) {
    final fact = _object(raw, 'actorFacts[]');
    return <String, Object?>{
      'actor': _required(fact, 'actor'),
      'actorLayer': _required(fact, 'actorLayer'),
      'availability': _compactAvailability(
        fact['availability'],
        currentStateOnly: currentStateOnly,
      ),
      'isShi': _required(fact, 'isShi'),
      'isYing': _required(fact, 'isYing'),
      'liuShen': _required(fact, 'liuShen'),
      'tags': _requiredList(fact, 'tags')
          .map(
            (tag) => _compactTag(
              tag,
              currentStateOnly: currentStateOnly,
            ),
          )
          .toList(growable: false),
      'interpretiveEvidence': _required(fact, 'interpretiveEvidence'),
    };
  }

  static Map<String, Object?> _compactUseSpiritOccurrence(
    Object? raw, {
    required bool currentStateOnly,
  }) {
    final occurrence = _object(raw, 'useSpiritOccurrences[]');
    return <String, Object?>{
      'actor': _required(occurrence, 'actor'),
      'availability': _compactAvailability(
        occurrence['availability'],
        currentStateOnly: currentStateOnly,
      ),
      'occurrenceRole': _required(occurrence, 'occurrenceRole'),
      'tagOccurrenceIds': _requiredList(occurrence, 'tags')
          .map((tag) => _required(_object(tag, 'tags[]'), 'occurrenceId'))
          .toList(growable: false),
      'phaseContributionOccurrenceIds':
          _requiredList(occurrence, 'phaseContributions')
              .map((effect) => _required(
                  _object(effect, 'phaseContributions[]'), 'occurrenceId'))
              .toList(growable: false),
    };
  }

  static Map<String, Object?> _compactRole(Object? raw) {
    final role = _object(raw, 'roles[]');
    final actor = _object(_required(role, 'actor'), 'roles[].actor');
    return <String, Object?>{
      'actorId': _required(actor, 'actorId'),
      'role': _required(role, 'role'),
      'roleRuleId': _required(role, 'roleRuleId'),
      'reason': _required(role, 'reason'),
      'selected': _required(role, 'selected'),
      'representative': _required(role, 'representative'),
    };
  }

  static Map<String, Object?> _compactAvailability(
    Object? raw, {
    required bool currentStateOnly,
  }) {
    if (raw == null) return const <String, Object?>{};
    final availability = _object(raw, 'availability');
    return <String, Object?>{
      'state': _required(availability, 'state'),
      'blockedPhases': _required(availability, 'blockedPhases'),
      'reasonRuleIds': _required(availability, 'reasonRuleIds'),
      'releaseConditionRuleIds': currentStateOnly
          ? const <Object?>[]
          : _required(availability, 'releaseConditionRuleIds'),
      'suppressedByOccurrenceIds':
          _required(availability, 'suppressedByOccurrenceIds'),
    };
  }

  static Map<String, Object?> _compactTag(
    Object? raw, {
    bool currentStateOnly = false,
  }) {
    final tag = _object(raw, 'tag');
    final compact = _pickRequired(tag, const <String>[
      'occurrenceId',
      'ruleId',
      'term',
      'category',
      'polarity',
      'priority',
      'reason',
      'relatedYao',
      'active',
      'sourceIds',
      'suppressedByRuleIds',
      'suppressedByOccurrenceIds',
      'decisionEligible',
      'decisionScopes',
      'forbiddenDecisionScopes',
      'authority',
      'evidenceLevel',
    ]);
    if (tag.containsKey('phase') || tag.containsKey('horizon')) {
      compact['phase'] = _required(tag, 'phase');
      compact['horizon'] = _required(tag, 'horizon');
    }
    if (currentStateOnly && compact['ruleId'] == _apparentVoidRuleId) {
      compact['reason'] = '旺或动而不作全空，当前按假空参与分析';
    } else if (currentStateOnly && compact['ruleId'] == _changedVoidRuleId) {
      compact['reason'] = '变爻旬空，当前仅记录化空状态';
    } else if (currentStateOnly && compact['ruleId'] == _tombOpenedRuleId) {
      compact['reason'] = '日辰作用后当前不受墓库限制';
    }
    return compact;
  }

  static Object? _compactVerdict(
    Object? raw, {
    required bool currentStateOnly,
  }) {
    if (raw == null || !currentStateOnly) return raw;
    final verdict = Map<String, Object?>.from(_object(raw, 'verdict'));
    verdict.remove('summary');
    return verdict;
  }

  static Map<String, Object?> _compactEffect(Object? raw) {
    final effect = _object(raw, 'directedEffects[]');
    final fromActor =
        _object(_required(effect, 'fromActor'), 'directedEffects[].fromActor');
    final toActor =
        _object(_required(effect, 'toActor'), 'directedEffects[].toActor');
    return <String, Object?>{
      'occurrenceId': _required(effect, 'occurrenceId'),
      'ruleId': _required(effect, 'ruleId'),
      'fromActorId': _required(fromActor, 'actorId'),
      'toActorId': _required(toActor, 'actorId'),
      'effect': _required(effect, 'effect'),
      'status': _required(effect, 'status'),
      'phase': _required(effect, 'phase'),
      'horizon': _required(effect, 'horizon'),
      'pathActorIds': _required(effect, 'pathActorIds'),
      'pathStep': _required(effect, 'pathStep'),
      'sourceIds': _required(effect, 'sourceIds'),
      'suppressedByRuleIds': _required(effect, 'suppressedByRuleIds'),
      'suppressedByOccurrenceIds':
          _required(effect, 'suppressedByOccurrenceIds'),
      'decisionEligible': _required(effect, 'decisionEligible'),
      'decisionScopes': _required(effect, 'decisionScopes'),
    };
  }

  static Map<String, Object?> _compactSource(
    Object? raw,
    Set<String> usedRuleIds,
  ) {
    final source = _object(raw, 'sources[]');
    return <String, Object?>{
      'sourceId': _required(source, 'sourceId'),
      'kind': _required(source, 'kind'),
      'title': _required(source, 'title'),
      'edition': _required(source, 'edition'),
      'publicLocator': _required(source, 'publicLocator'),
      'adoptionStatus': _required(source, 'adoptionStatus'),
      'scope': _required(source, 'scope'),
      'adjudication': _required(source, 'adjudication'),
      if (source.containsKey('limitations'))
        'limitations': source['limitations'],
      'references': _requiredList(source, 'references')
          .where((rawReference) {
            final reference = _object(rawReference, 'references[]');
            return usedRuleIds.contains(_required(reference, 'ruleId'));
          })
          .map(_compactReference)
          .toList(growable: false),
    };
  }

  static Map<String, Object?> _compactReference(Object? raw) {
    final reference = _object(raw, 'references[]');
    final result = _pickRequired(reference, const <String>[
      'ruleId',
      'primaryTerm',
      'locator',
      'evidenceLevel',
      'referenceKind',
      'adoptionNote',
    ]);
    if (reference.containsKey('quote')) result['quote'] = reference['quote'];
    return result;
  }

  static Map<String, Object?> _pickRequired(
    Map<String, Object?> source,
    List<String> keys,
  ) =>
      <String, Object?>{for (final key in keys) key: _required(source, key)};

  static Object? _required(Map<String, Object?> source, String key) {
    if (!source.containsKey(key)) {
      throw StateError('Liuyao AI projection field is absent: $key');
    }
    return source[key];
  }

  static List<Object?> _requiredList(
    Map<String, Object?> source,
    String key,
  ) {
    final raw = _required(source, key);
    if (raw is! List) {
      throw StateError('Liuyao AI projection field is not a list: $key');
    }
    return raw.cast<Object?>();
  }

  static Map<String, Object?> _object(Object? raw, String context) {
    if (raw is! Map) {
      throw StateError('Liuyao AI projection object is invalid: $context');
    }
    return raw.cast<String, Object?>();
  }

  static Object? _copyJson(Object? value, String context) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is List) {
      return value
          .map((item) => _copyJson(item, '$context[]'))
          .toList(growable: false);
    }
    if (value is Map) {
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw StateError('Liuyao AI projection key is invalid: $context');
        }
        result[key] = _copyJson(entry.value, '$context.$key');
      }
      return result;
    }
    throw StateError(
      'Liuyao AI projection value is not JSON-safe: $context',
    );
  }

  static Object? _omitEvidence(
    Object? value, {
    required Set<String> occurrenceIds,
    required Set<String> ruleIds,
    bool occurrenceReference = false,
    bool ruleReference = false,
  }) {
    if (value is String) {
      if ((occurrenceReference && occurrenceIds.contains(value)) ||
          (ruleReference && ruleIds.contains(value))) {
        return _omitted;
      }
      return value;
    }
    if (value == null || value is num || value is bool) return value;
    if (value is List) {
      final result = <Object?>[];
      for (final item in value) {
        final compacted = _omitEvidence(
          item,
          occurrenceIds: occurrenceIds,
          ruleIds: ruleIds,
          occurrenceReference: occurrenceReference,
          ruleReference: ruleReference,
        );
        if (!identical(compacted, _omitted)) result.add(compacted);
      }
      return result;
    }
    if (value is Map) {
      if (occurrenceIds.contains(value['occurrenceId']) ||
          ruleIds.contains(value['ruleId'])) {
        return _omitted;
      }
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw StateError('Liuyao AI projection key is invalid while pruning');
        }
        final compacted = _omitEvidence(
          entry.value,
          occurrenceIds: occurrenceIds,
          ruleIds: ruleIds,
          occurrenceReference:
              occurrenceReference || key.endsWith('OccurrenceIds'),
          ruleReference: ruleReference || key.endsWith('RuleIds'),
        );
        if (!identical(compacted, _omitted)) result[key] = compacted;
      }
      return result;
    }
    throw StateError(
        'Liuyao AI projection value is not JSON-safe while pruning');
  }

  static Set<String> _collectResolvedBindingOccurrenceIds(Object? value) {
    final result = <String>{};
    if (value is! List) return result;
    for (final rawFact in value) {
      if (rawFact is! Map<Object?, Object?>) continue;
      final rawTags = rawFact['tags'];
      if (rawTags is! List) continue;
      final tags =
          rawTags.whereType<Map<Object?, Object?>>().toList(growable: false);
      final openedRelations = <String>{};
      for (final tag in tags) {
        if (tag['ruleId'] != _bindingOpenedRuleId || tag['active'] != true) {
          continue;
        }
        final occurrenceId = tag['occurrenceId'];
        if (occurrenceId is String && occurrenceId.isNotEmpty) {
          result.add(occurrenceId);
          openedRelations.add(_relatedYaoKey(tag));
        }
      }
      for (final tag in tags) {
        if (tag['ruleId'] != _mutualBindingRuleId ||
            tag['active'] != true ||
            !openedRelations.contains(_relatedYaoKey(tag))) {
          continue;
        }
        final occurrenceId = tag['occurrenceId'];
        if (occurrenceId is String && occurrenceId.isNotEmpty) {
          result.add(occurrenceId);
        }
      }
    }
    return result;
  }

  static String _relatedYaoKey(Map<Object?, Object?> tag) {
    final relatedYao = tag['relatedYao'];
    if (relatedYao is! List) return '';
    return relatedYao.join(',');
  }

  static Set<String> _collectOccurrenceIds(Object? value) {
    final result = <String>{};

    void visit(Object? item) {
      if (item is List) {
        for (final child in item) {
          visit(child);
        }
        return;
      }
      if (item is! Map) return;
      for (final entry in item.entries) {
        if (entry.key == 'occurrenceId' && entry.value is String) {
          result.add(entry.value as String);
        }
        visit(entry.value);
      }
    }

    visit(value);
    return result;
  }

  static Set<String> _collectReferencedOccurrenceIds(Object? value) {
    final result = <String>{};

    void visit(Object? item) {
      if (item is List) {
        for (final child in item) {
          visit(child);
        }
        return;
      }
      if (item is! Map) return;
      for (final entry in item.entries) {
        final key = entry.key;
        final child = entry.value;
        if (key == 'occurrenceId' && child is String) {
          result.add(child);
        } else if (key is String && key.endsWith('OccurrenceIds')) {
          if (child is List) {
            result.addAll(child.whereType<String>());
          } else if (child is Map) {
            for (final ids in child.values.whereType<List<Object?>>()) {
              result.addAll(ids.whereType<String>());
            }
          }
        }
        visit(child);
      }
    }

    visit(value);
    return result;
  }

  static Map<String, String> _indexOccurrenceRuleIds(Object? value) {
    final result = <String, String>{};

    void visit(Object? item) {
      if (item is List) {
        for (final child in item) {
          visit(child);
        }
        return;
      }
      if (item is! Map) return;
      final occurrenceId = item['occurrenceId'];
      final ruleId = item['ruleId'];
      if (occurrenceId is String && ruleId is String) {
        final existing = result[occurrenceId];
        if (existing != null && existing != ruleId) {
          throw StateError(
            'Liuyao occurrence maps to multiple rules: $occurrenceId',
          );
        }
        result[occurrenceId] = ruleId;
      }
      for (final child in item.values) {
        visit(child);
      }
    }

    visit(value);
    return result;
  }

  static Set<String> _collectRuleIds(Object? value) {
    final result = <String>{};

    void visit(Object? item) {
      if (item is List) {
        for (final child in item) {
          visit(child);
        }
        return;
      }
      if (item is! Map) return;
      for (final entry in item.entries) {
        final key = entry.key;
        final child = entry.value;
        if (key is String) {
          final isSingleRuleId = key == 'ruleId' ||
              key == 'decisionRowId' ||
              key == 'matchedDecisionRowId' ||
              key.endsWith('RuleId');
          final isRuleIdList = key.endsWith('RuleIds');
          if (isSingleRuleId && child is String && child.isNotEmpty) {
            result.add(child);
          } else if (isRuleIdList && child is List) {
            result
                .addAll(child.whereType<String>().where((id) => id.isNotEmpty));
          }
        }
        visit(child);
      }
    }

    visit(value);
    return result;
  }
}
