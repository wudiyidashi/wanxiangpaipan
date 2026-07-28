import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const String _supportedSchemaVersion = '1.0.0';
const int _maximumAllowedShortQuoteCharacters = 160;
const Set<String> _evidenceLevels = <String>{'A', 'B', 'C', 'D'};
const Set<String> _ruleStatuses = <String>{
  'adopted',
  'pending',
  'excluded',
  'disputed',
  'deprecated',
};
const Set<String> _variantStatuses = <String>{
  'unresolved',
  'provisional',
  'adopted',
  'rejected',
};
const Set<String> _caseStatuses = <String>{
  'candidate',
  'pendingScan',
  'scanVerified',
  'approved',
  'excluded',
};
const Set<String> _ruleFamilies = <String>{
  'pan',
  'shenjiang',
  'jiuzongmen',
  'derivedFacts',
  'shensha',
  'kejing',
  'bifa',
  'nianming',
  'classSpirit',
  'judgment',
  'timing',
};
const Set<String> _sourceLayers = <String>{
  ..._ruleFamilies,
  'externalCases',
};
const Set<String> _sourceUsages = <String>{
  'primaryBaseline',
  'judgmentBaseline',
  'externalCase',
  'supplement',
  'variantLocator',
  'searchLocator',
};
const Map<String, int> _mandatoryExactRuleCounts = <String, int>{
  'shensha': 238,
  'kejing': 64,
  'bifa': 100,
};
const Set<String> _requiredForbiddenExtensions = <String>{
  '.pdf',
  '.djvu',
  '.tif',
  '.tiff',
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.epub',
  '.mobi',
};
const Set<String> _requiredSchemaFiles = <String>{
  'schema/source.schema.json',
  'schema/rule.schema.json',
  'schema/variant.schema.json',
  'schema/case.schema.json',
};
const Map<String, String> _requiredSchemaIds = <String, String>{
  'schema/source.schema.json':
      'https://wanxiang-paipan.local/schema/daliuren/classics/source.schema.json',
  'schema/rule.schema.json':
      'https://wanxiang-paipan.local/schema/daliuren/classics/rule.schema.json',
  'schema/variant.schema.json':
      'https://wanxiang-paipan.local/schema/daliuren/classics/variant.schema.json',
  'schema/case.schema.json':
      'https://wanxiang-paipan.local/schema/daliuren/classics/case.schema.json',
};
const Set<String> _requiredRuleFiles = <String>{
  'rules/pan.json',
  'rules/shenjiang.json',
  'rules/jiuzongmen.json',
  'rules/derived-facts.json',
  'rules/shensha.json',
  'rules/kejing.json',
  'rules/bifa.json',
  'rules/nianming.json',
  'rules/class-spirit.json',
  'rules/judgment.json',
  'rules/timing.json',
};
const Set<String> _requiredCaseFiles = <String>{
  'cases/duanan.json',
  'cases/cunyan.json',
  'cases/zhinan.json',
};
final RegExp _placeholderPattern = RegExp(
  r'\b(?:TODO|TBD|PLACEHOLDER)\b|<[^>]+>|待填写|待补充',
  caseSensitive: false,
);
final RegExp _sourceIdPattern = RegExp(
  r'^dlr\.source\.[a-z0-9][a-z0-9.-]*$',
);
final RegExp _candidateIdPattern = RegExp(
  r'^dlr\.candidate\.[a-z0-9][a-z0-9.-]*$',
);
final RegExp _ruleIdPattern = RegExp(
  r'^dlr\.rule\.[a-zA-Z0-9][a-zA-Z0-9.-]*$',
);
final RegExp _caseIdPattern = RegExp(
  r'^dlr\.case\.[a-z0-9][a-z0-9.-]*$',
);
final RegExp _variantGroupIdPattern = RegExp(
  r'^dlr\.variant\.[a-z0-9][a-z0-9.-]*$',
);
final RegExp _variantOptionIdPattern = RegExp(
  r'^[a-z0-9][a-z0-9.-]*$',
);

class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  @override
  String toString() => '[$code] $path: $message';
}

class ValidationResult {
  const ValidationResult({
    required this.issues,
    required this.coverageMarkdown,
    required this.coverageReportPath,
  });

  final List<ValidationIssue> issues;
  final String coverageMarkdown;
  final String coverageReportPath;

  bool get isValid => issues.isEmpty;
}

class ClassicEvidenceValidator {
  ClassicEvidenceValidator({
    required this.registryRoot,
    required this.repositoryRoot,
  });

  final Directory registryRoot;
  final Directory repositoryRoot;

  final List<ValidationIssue> _issues = <ValidationIssue>[];
  final Map<String, _SourceInfo> _sources = <String, _SourceInfo>{};
  final Map<String, _RuleInfo> _rules = <String, _RuleInfo>{};
  final Map<String, _CaseInfo> _cases = <String, _CaseInfo>{};
  final Map<String, _VariantInfo> _variants = <String, _VariantInfo>{};
  final Map<String, List<_RuleInfo>> _families = <String, List<_RuleInfo>>{};
  final List<String> _requiredFamilies = <String>[];
  final Map<String, int> _exactRuleCounts = <String, int>{};
  final List<String> _unregisteredSourceTitles = <String>[];
  final List<String> _caseCatalogBlockers = <String>[];

  int _maxShortQuoteCharacters = _maximumAllowedShortQuoteCharacters;
  String _coverageReportPath = 'docs/research/daliuren/evidence-coverage.md';

  ValidationResult validate() {
    _reset();

    final File manifestFile = File(p.join(registryRoot.path, 'manifest.json'));
    final Map<String, Object?>? manifest = _readObjectFile(
      manifestFile,
      'manifest.json',
    );
    if (manifest == null) {
      return _result();
    }

    _validateManifest(manifest);
    _validateForbiddenFiles(manifest);
    _validateSchemaFiles(manifest);
    _loadSources(manifest);
    _loadRules(manifest);
    _loadCases(manifest);
    _loadVariants(manifest);
    _validateCrossReferences();
    _validateFamilyConstraints();

    return _result();
  }

  void _reset() {
    _issues.clear();
    _sources.clear();
    _rules.clear();
    _cases.clear();
    _variants.clear();
    _families.clear();
    _requiredFamilies.clear();
    _exactRuleCounts.clear();
    _unregisteredSourceTitles.clear();
    _caseCatalogBlockers.clear();
    _maxShortQuoteCharacters = _maximumAllowedShortQuoteCharacters;
    _coverageReportPath = 'docs/research/daliuren/evidence-coverage.md';
  }

  ValidationResult _result() => ValidationResult(
        issues: List<ValidationIssue>.unmodifiable(_issues),
        coverageMarkdown: _buildCoverageMarkdown(),
        coverageReportPath: _coverageReportPath,
      );

  void _validateManifest(Map<String, Object?> manifest) {
    const Set<String> keys = <String>{
      'schemaVersion',
      'registryId',
      'sourceFile',
      'variantFile',
      'schemaFiles',
      'ruleFiles',
      'caseFiles',
      'requiredFamilies',
      'exactRuleCounts',
      'maxShortQuoteCharacters',
      'forbiddenExtensions',
      'coverageReportPath',
    };
    _requireExactKeys(manifest, keys, 'manifest.json');

    _requireSchemaVersion(manifest, 'manifest.json');
    _requireString(manifest, 'registryId', 'manifest.json');
    final String? sourceFile =
        _requireRelativePath(manifest, 'sourceFile', 'manifest.json');
    if (sourceFile != null && sourceFile != 'sources.json') {
      _add(
        'manifest.sourcePath',
        'manifest.json.sourceFile',
        'The stable source registry path is sources.json.',
      );
    }
    final String? variantFile =
        _requireRelativePath(manifest, 'variantFile', 'manifest.json');
    if (variantFile != null && variantFile != 'variants.json') {
      _add(
        'manifest.variantPath',
        'manifest.json.variantFile',
        'The stable variant registry path is variants.json.',
      );
    }
    final List<String>? schemaFiles =
        _requireStringList(manifest, 'schemaFiles', 'manifest.json');
    final List<String>? ruleFiles =
        _requireStringList(manifest, 'ruleFiles', 'manifest.json');
    final List<String>? caseFiles =
        _requireStringList(manifest, 'caseFiles', 'manifest.json');
    if (schemaFiles != null) {
      _validateRequiredPaths(
        schemaFiles,
        _requiredSchemaFiles,
        'manifest.json.schemaFiles',
      );
    }
    if (ruleFiles != null) {
      _validateRequiredPaths(
        ruleFiles,
        _requiredRuleFiles,
        'manifest.json.ruleFiles',
      );
    }
    if (caseFiles != null) {
      _validateRequiredPaths(
        caseFiles,
        _requiredCaseFiles,
        'manifest.json.caseFiles',
      );
    }
    final List<String>? forbiddenExtensions = _requireStringList(
      manifest,
      'forbiddenExtensions',
      'manifest.json',
    );
    if (forbiddenExtensions != null) {
      _checkDuplicates(
        forbiddenExtensions,
        'manifest.extensionDuplicate',
        'manifest.json.forbiddenExtensions',
      );
    }

    final List<String>? required = _requireStringList(
      manifest,
      'requiredFamilies',
      'manifest.json',
    );
    if (required != null) {
      _requiredFamilies.addAll(required);
      _checkDuplicates(required, 'manifest.familyDuplicate',
          'manifest.json.requiredFamilies');
      _validateEnumValues(
        required,
        _ruleFamilies,
        'manifest.json.requiredFamilies',
      );
      for (final String family in _ruleFamilies) {
        if (!required.contains(family)) {
          _add(
            'manifest.requiredFamilyMissing',
            'manifest.json.requiredFamilies',
            'The validator contract requires family $family.',
          );
          _requiredFamilies.add(family);
        }
      }
    }

    final Map<String, Object?>? exactCounts = _requireObject(
      manifest,
      'exactRuleCounts',
      'manifest.json',
    );
    if (exactCounts != null) {
      for (final MapEntry<String, Object?> entry in exactCounts.entries) {
        if (entry.value is! int || (entry.value! as int) < 0) {
          _add(
            'shape.type',
            'manifest.json.exactRuleCounts.${entry.key}',
            'Expected a non-negative integer.',
          );
          continue;
        }
        _exactRuleCounts[entry.key] = entry.value! as int;
      }
      for (final MapEntry<String, int> requiredCount
          in _mandatoryExactRuleCounts.entries) {
        if (exactCounts[requiredCount.key] != requiredCount.value) {
          _add(
            'manifest.exactRuleConstraint',
            'manifest.json.exactRuleCounts.${requiredCount.key}',
            'The validator contract requires exactly ${requiredCount.value} ${requiredCount.key} entries.',
          );
        }
        _exactRuleCounts[requiredCount.key] = requiredCount.value;
      }
    }

    final Object? maxQuote = manifest['maxShortQuoteCharacters'];
    if (maxQuote is int &&
        maxQuote > 0 &&
        maxQuote <= _maximumAllowedShortQuoteCharacters) {
      _maxShortQuoteCharacters = maxQuote;
    } else {
      _add(
        'shape.type',
        'manifest.json.maxShortQuoteCharacters',
        'Expected an integer from 1 to $_maximumAllowedShortQuoteCharacters.',
      );
    }

    final String? reportPath = _requireRelativePath(
      manifest,
      'coverageReportPath',
      'manifest.json',
    );
    if (reportPath != null) {
      _coverageReportPath = reportPath;
    }

    for (final String listKey in <String>[
      'schemaFiles',
      'ruleFiles',
      'caseFiles',
    ]) {
      final List<String>? paths = _stringList(manifest[listKey]);
      if (paths == null) {
        continue;
      }
      _checkDuplicates(
          paths, 'manifest.pathDuplicate', 'manifest.json.$listKey');
      for (final String path in paths) {
        _validateRelativePath(path, 'manifest.json.$listKey');
      }
    }
  }

  void _validateForbiddenFiles(Map<String, Object?> manifest) {
    final List<String> extensions =
        _stringList(manifest['forbiddenExtensions']) ?? <String>[];
    for (final String requiredExtension in _requiredForbiddenExtensions) {
      if (!extensions.contains(requiredExtension)) {
        _add(
          'manifest.forbiddenExtensionMissing',
          'manifest.json.forbiddenExtensions',
          'The validator contract must forbid $requiredExtension files.',
        );
      }
    }
    if (!registryRoot.existsSync()) {
      _add(
        'path.missing',
        registryRoot.path,
        'Registry root does not exist.',
      );
      return;
    }
    for (final FileSystemEntity entity
        in registryRoot.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final String extension = p.extension(entity.path).toLowerCase();
      if (extensions.contains(extension)) {
        _add(
          'scan.forbidden',
          p.relative(entity.path, from: repositoryRoot.path),
          'Scans and image/PDF source files must not be committed.',
        );
      }
    }
  }

  void _validateSchemaFiles(Map<String, Object?> manifest) {
    final List<String> paths =
        _stringList(manifest['schemaFiles']) ?? <String>[];
    for (final String relativePath in paths) {
      final Map<String, Object?>? schema = _readRegistryObject(relativePath);
      if (schema == null) {
        continue;
      }
      final String path = relativePath.replaceAll('\\', '/');
      if (schema[r'$schema'] !=
          'https://json-schema.org/draft/2020-12/schema') {
        _add(
          'schema.draft',
          path,
          'Schema must declare JSON Schema draft 2020-12.',
        );
      }
      if (schema[r'$id'] is! String || (schema[r'$id']! as String).isEmpty) {
        _add('schema.id', path, 'Schema must declare a non-empty \$id.');
      } else if (_requiredSchemaIds[path] != null &&
          schema[r'$id'] != _requiredSchemaIds[path]) {
        _add(
          'schema.id',
          path,
          'Schema \$id must be ${_requiredSchemaIds[path]}.',
        );
      }
      if (schema['type'] != 'object') {
        _add('schema.rootType', path, 'Schema root type must be object.');
      }
    }
  }

  void _loadSources(Map<String, Object?> manifest) {
    final String? sourcePath = _string(manifest['sourceFile']);
    if (sourcePath == null) {
      return;
    }
    final Map<String, Object?>? document = _readRegistryObject(sourcePath);
    if (document == null) {
      return;
    }
    const Set<String> documentKeys = <String>{
      'schemaVersion',
      'sources',
      'unregisteredCandidates',
    };
    _requireExactKeys(document, documentKeys, sourcePath);
    _requireSchemaVersion(document, sourcePath);

    final List<Object?>? sourceObjects = _requireList(
      document,
      'sources',
      sourcePath,
    );
    if (sourceObjects != null) {
      for (int index = 0; index < sourceObjects.length; index++) {
        final String objectPath = '$sourcePath.sources[$index]';
        final Map<String, Object?>? source = _asObject(
          sourceObjects[index],
          objectPath,
        );
        if (source != null) {
          _validateSource(source, objectPath);
        }
      }
    }

    final List<Object?>? candidates = _requireList(
      document,
      'unregisteredCandidates',
      sourcePath,
    );
    if (candidates != null) {
      final Set<String> candidateIds = <String>{};
      for (int index = 0; index < candidates.length; index++) {
        final String objectPath = '$sourcePath.unregisteredCandidates[$index]';
        final Map<String, Object?>? candidate = _asObject(
          candidates[index],
          objectPath,
        );
        if (candidate == null) {
          continue;
        }
        const Set<String> keys = <String>{
          'candidateId',
          'title',
          'status',
          'reason',
        };
        _requireExactKeys(candidate, keys, objectPath);
        final String? candidateId = _requirePatternString(
          candidate,
          'candidateId',
          _candidateIdPattern,
          objectPath,
        );
        final String? title = _requireString(candidate, 'title', objectPath);
        _requireEnum(
          candidate,
          'status',
          <String>{'notLocated', 'metadataIncomplete', 'rejected'},
          objectPath,
        );
        _requireString(candidate, 'reason', objectPath);
        if (candidateId != null && !candidateIds.add(candidateId)) {
          _add(
            'source.candidateDuplicate',
            '$objectPath.candidateId',
            'Duplicate candidateId $candidateId.',
          );
        }
        if (title != null) {
          _unregisteredSourceTitles.add(title);
        }
      }
    }
  }

  void _validateSource(Map<String, Object?> source, String objectPath) {
    const Set<String> keys = <String>{
      'sourceId',
      'sourceType',
      'title',
      'authorsEditors',
      'edition',
      'repository',
      'identifier',
      'accessUrl',
      'accessedAt',
      'verificationStatus',
      'locatorOnly',
      'usage',
      'ruleLayers',
      'volumes',
      'rightsNote',
      'limitations',
    };
    _requireExactKeys(source, keys, objectPath);
    final String? sourceId = _requirePatternString(
      source,
      'sourceId',
      _sourceIdPattern,
      objectPath,
    );
    final String? sourceType = _requireEnum(
      source,
      'sourceType',
      <String>{'scan', 'transcription', 'ocr', 'commentary'},
      objectPath,
    );
    _requireString(source, 'title', objectPath);
    _requireStringList(source, 'authorsEditors', objectPath);
    _requireString(source, 'edition', objectPath);
    _requireString(source, 'repository', objectPath);
    _requireString(source, 'identifier', objectPath);
    _requireAbsoluteUri(source, 'accessUrl', objectPath);
    _requireDate(source, 'accessedAt', objectPath);
    final String? status = _requireEnum(
      source,
      'verificationStatus',
      <String>{'candidate', 'metadataVerified', 'scanVerified', 'approved'},
      objectPath,
    );
    final bool? locatorOnly = _requireBool(source, 'locatorOnly', objectPath);
    final List<String>? usages = _requireStringList(
      source,
      'usage',
      objectPath,
    );
    if (usages != null) {
      if (usages.isEmpty) {
        _add('shape.empty', '$objectPath.usage',
            'At least one usage is required.');
      }
      _validateEnumValues(usages, _sourceUsages, '$objectPath.usage');
    }
    final List<String>? ruleLayers = _requireStringList(
      source,
      'ruleLayers',
      objectPath,
    );
    if (ruleLayers != null) {
      _checkDuplicates(
        ruleLayers,
        'source.ruleLayerDuplicate',
        '$objectPath.ruleLayers',
      );
      _validateEnumValues(
        ruleLayers,
        _sourceLayers,
        '$objectPath.ruleLayers',
      );
    }
    _requireString(source, 'rightsNote', objectPath);
    final List<String>? limitations = _requireStringList(
      source,
      'limitations',
      objectPath,
    );
    if (limitations != null && limitations.isEmpty) {
      _add(
        'shape.empty',
        '$objectPath.limitations',
        'At least one source limitation is required.',
      );
    }

    final Map<String, _VolumeInfo> volumes = <String, _VolumeInfo>{};
    final List<Object?>? volumeObjects = _requireList(
      source,
      'volumes',
      objectPath,
    );
    if (volumeObjects != null) {
      if (volumeObjects.isEmpty) {
        _add('shape.empty', '$objectPath.volumes',
            'At least one volume is required.');
      }
      for (int index = 0; index < volumeObjects.length; index++) {
        final String volumePath = '$objectPath.volumes[$index]';
        final Map<String, Object?>? volume = _asObject(
          volumeObjects[index],
          volumePath,
        );
        if (volume == null) {
          continue;
        }
        const Set<String> volumeKeys = <String>{
          'volumeLabel',
          'identifier',
          'accessUrl',
          'remoteFiles',
          'pagination',
        };
        _requireExactKeys(volume, volumeKeys, volumePath);
        final String? label = _requireString(volume, 'volumeLabel', volumePath);
        _requireString(volume, 'identifier', volumePath);
        _requireAbsoluteUri(volume, 'accessUrl', volumePath);
        _validateRemoteFiles(volume, volumePath);
        final _VolumeInfo? volumeInfo = _validatePagination(volume, volumePath);
        if (label != null && volumeInfo != null) {
          if (volumes.containsKey(label)) {
            _add(
              'source.volumeDuplicate',
              '$volumePath.volumeLabel',
              'Duplicate volume label $label.',
            );
          } else {
            volumes[label] = volumeInfo;
          }
        }
      }
    }

    if (locatorOnly == true && status == 'approved') {
      _add(
        'source.approvedLocator',
        objectPath,
        'A locator-only source cannot be approved.',
      );
    }
    if (sourceType != 'scan' &&
        (status == 'scanVerified' || status == 'approved')) {
      _add(
        'source.scanStatusNonScan',
        objectPath,
        'Only an image/scan source can be scan-verified or approved.',
      );
    }

    if (sourceId != null &&
        sourceType != null &&
        locatorOnly != null &&
        status != null) {
      if (_sources.containsKey(sourceId)) {
        _add(
          'source.duplicate',
          '$objectPath.sourceId',
          'Duplicate sourceId $sourceId.',
        );
      } else {
        _sources[sourceId] = _SourceInfo(
          sourceId: sourceId,
          sourceType: sourceType,
          locatorOnly: locatorOnly,
          verificationStatus: status,
          ruleLayers: ruleLayers?.toSet() ?? <String>{},
          volumes: volumes,
        );
      }
    }
  }

  void _validateRemoteFiles(Map<String, Object?> volume, String volumePath) {
    final List<Object?>? files = _requireList(
      volume,
      'remoteFiles',
      volumePath,
    );
    if (files == null) {
      return;
    }
    if (files.isEmpty) {
      _add('shape.empty', '$volumePath.remoteFiles',
          'At least one file is required.');
    }
    final Set<String> names = <String>{};
    for (int index = 0; index < files.length; index++) {
      final String filePath = '$volumePath.remoteFiles[$index]';
      final Map<String, Object?>? file = _asObject(files[index], filePath);
      if (file == null) {
        continue;
      }
      const Set<String> keys = <String>{'name', 'format', 'sizeBytes'};
      _requireExactKeys(file, keys, filePath);
      final String? name = _requireString(file, 'name', filePath);
      _requireString(file, 'format', filePath);
      final Object? size = file['sizeBytes'];
      if (size != null && (size is! int || size < 0)) {
        _add('shape.type', '$filePath.sizeBytes',
            'Expected null or a non-negative integer.');
      }
      if (name != null && !names.add(name)) {
        _add('source.fileDuplicate', '$filePath.name',
            'Duplicate remote filename $name.');
      }
    }
  }

  _VolumeInfo? _validatePagination(
    Map<String, Object?> volume,
    String volumePath,
  ) {
    final Map<String, Object?>? pagination = _requireObject(
      volume,
      'pagination',
      volumePath,
    );
    if (pagination == null) {
      return null;
    }
    const Set<String> keys = <String>{
      'scanLeafBase',
      'leafCount',
      'pdfPageBase',
      'mappingRule',
      'mappingStatus',
      'printedLeafScheme',
      'notes',
    };
    _requireExactKeys(pagination, keys, '$volumePath.pagination');
    final int? scanLeafBase = _nullableNonNegativeInt(
      pagination['scanLeafBase'],
      '$volumePath.pagination.scanLeafBase',
    );
    final int? leafCount = _nullablePositiveInt(
      pagination['leafCount'],
      '$volumePath.pagination.leafCount',
    );
    final int? pdfPageBase = _nullablePositiveInt(
      pagination['pdfPageBase'],
      '$volumePath.pagination.pdfPageBase',
    );
    _requireEnum(
      pagination,
      'mappingRule',
      <String>{
        'pdfPageEqualsScanLeaf',
        'pdfPageEqualsScanLeafPlusOne',
        'nonLinear',
        'notApplicable',
        'unverified',
      },
      '$volumePath.pagination',
    );
    final String? mappingStatus = _requireEnum(
      pagination,
      'mappingStatus',
      <String>{
        'verifiedFromScandata',
        'partial',
        'unverified',
        'notApplicable'
      },
      '$volumePath.pagination',
    );
    _requireString(pagination, 'printedLeafScheme', '$volumePath.pagination');
    _requireString(pagination, 'notes', '$volumePath.pagination');
    if (mappingStatus == 'verifiedFromScandata' &&
        (scanLeafBase == null || leafCount == null || pdfPageBase == null)) {
      _add(
        'source.paginationIncomplete',
        '$volumePath.pagination',
        'Verified scan/PDF mapping requires leaf and PDF bounds.',
      );
    }
    return _VolumeInfo(
      scanLeafBase: scanLeafBase,
      leafCount: leafCount,
      pdfPageBase: pdfPageBase,
    );
  }

  void _loadRules(Map<String, Object?> manifest) {
    final List<String> paths = _stringList(manifest['ruleFiles']) ?? <String>[];
    for (final String relativePath in paths) {
      final Map<String, Object?>? document = _readRegistryObject(relativePath);
      if (document == null) {
        continue;
      }
      const Set<String> keys = <String>{
        'schemaVersion',
        'family',
        'catalogStatus',
        'description',
        'expectedEntryCount',
        'entries',
      };
      _requireExactKeys(document, keys, relativePath);
      _requireSchemaVersion(document, relativePath);
      final String? family = _requireEnum(
        document,
        'family',
        _ruleFamilies,
        relativePath,
      );
      _requireEnum(
        document,
        'catalogStatus',
        <String>{'approved', 'partial', 'locatorOnly', 'unresolved'},
        relativePath,
      );
      _requireString(document, 'description', relativePath);
      final int? expectedEntryCount = _requireNonNegativeInt(
        document,
        'expectedEntryCount',
        relativePath,
      );
      final List<Object?>? entries = _requireList(
        document,
        'entries',
        relativePath,
      );
      if (family == null || entries == null) {
        continue;
      }
      if (_families.containsKey(family)) {
        _add(
          'family.duplicate',
          '$relativePath.family',
          'Family $family is declared by more than one file.',
        );
      }
      final List<_RuleInfo> familyRules = _families.putIfAbsent(
        family,
        () => <_RuleInfo>[],
      );
      if (expectedEntryCount != null && expectedEntryCount != entries.length) {
        _add(
          'family.declaredCount',
          '$relativePath.expectedEntryCount',
          'Declared $expectedEntryCount entries but found ${entries.length}.',
        );
      }
      final Set<int> ordinals = <int>{};
      for (int index = 0; index < entries.length; index++) {
        final String rulePath = '$relativePath.entries[$index]';
        final Map<String, Object?>? entry = _asObject(entries[index], rulePath);
        if (entry == null) {
          continue;
        }
        final _RuleInfo? info = _validateRule(entry, rulePath, family);
        if (info == null) {
          continue;
        }
        if (!ordinals.add(info.ordinal)) {
          _add(
            'ordinal.duplicate',
            '$rulePath.ordinal',
            'Duplicate ordinal ${info.ordinal} in $family.',
          );
        }
        familyRules.add(info);
        if (_rules.containsKey(info.ruleId)) {
          _add(
            'rule.duplicate',
            '$rulePath.ruleId',
            'Duplicate ruleId ${info.ruleId}.',
          );
        } else {
          _rules[info.ruleId] = info;
        }
      }
      final List<int> sortedOrdinals = ordinals.toList()..sort();
      for (int index = 0; index < sortedOrdinals.length; index++) {
        if (sortedOrdinals[index] != index + 1) {
          _add(
            'ordinal.nonContiguous',
            '$relativePath.entries',
            'Ordinals must be contiguous from 1; found ${sortedOrdinals[index]} at position ${index + 1}.',
          );
          break;
        }
      }
    }
  }

  _RuleInfo? _validateRule(
    Map<String, Object?> rule,
    String rulePath,
    String documentFamily,
  ) {
    const Set<String> keys = <String>{
      'ruleId',
      'family',
      'subfamily',
      'ordinal',
      'traditionalName',
      'adoptedStatus',
      'conditionsSummary',
      'prioritySummary',
      'interpretation',
      'evidenceLevel',
      'locatorOnly',
      'executableApproved',
      'sourceRefs',
      'variantGroupId',
      'adoptedVariantId',
      'fixtureIds',
      'targetCapabilityId',
      'targetCodeDomain',
      'notes',
    };
    _requireExactKeys(rule, keys, rulePath);
    final String? ruleId = _requirePatternString(
      rule,
      'ruleId',
      _ruleIdPattern,
      rulePath,
    );
    final String? family = _requireEnum(
      rule,
      'family',
      _ruleFamilies,
      rulePath,
    );
    _requireString(rule, 'subfamily', rulePath);
    final int? ordinal = _requirePositiveInt(rule, 'ordinal', rulePath);
    _requireContentString(rule, 'traditionalName', rulePath);
    final String? status = _requireEnum(
      rule,
      'adoptedStatus',
      _ruleStatuses,
      rulePath,
    );
    _requireContentString(rule, 'conditionsSummary', rulePath);
    _requireContentString(rule, 'prioritySummary', rulePath);
    _requireContentString(rule, 'interpretation', rulePath);
    final String? evidenceLevel = _requireEnum(
      rule,
      'evidenceLevel',
      _evidenceLevels,
      rulePath,
    );
    final bool? locatorOnly = _requireBool(rule, 'locatorOnly', rulePath);
    final bool? executable = _requireBool(rule, 'executableApproved', rulePath);
    final List<String> fixtureIds =
        _requireStringList(rule, 'fixtureIds', rulePath) ?? <String>[];
    _checkDuplicates(
      fixtureIds,
      'rule.fixtureDuplicate',
      '$rulePath.fixtureIds',
    );
    _validatePatternValues(
      fixtureIds,
      _caseIdPattern,
      '$rulePath.fixtureIds',
    );
    _requireStringList(rule, 'notes', rulePath);
    _requireContentString(rule, 'targetCapabilityId', rulePath);
    _requireContentString(rule, 'targetCodeDomain', rulePath);
    final String? variantGroupId = _nullableStringField(
      rule,
      'variantGroupId',
      rulePath,
    );
    final String? adoptedVariantId = _nullableStringField(
      rule,
      'adoptedVariantId',
      rulePath,
    );
    if (variantGroupId != null &&
        !_variantGroupIdPattern.hasMatch(variantGroupId)) {
      _add(
        'id.pattern',
        '$rulePath.variantGroupId',
        'Value does not match ${_variantGroupIdPattern.pattern}.',
      );
    }
    if (adoptedVariantId != null &&
        !_variantOptionIdPattern.hasMatch(adoptedVariantId)) {
      _add(
        'id.pattern',
        '$rulePath.adoptedVariantId',
        'Value does not match ${_variantOptionIdPattern.pattern}.',
      );
    }

    if (family != null && family != documentFamily) {
      _add(
        'family.mismatch',
        '$rulePath.family',
        'Rule family $family does not match document family $documentFamily.',
      );
    }

    final List<_SourceRefInfo> sourceRefs = <_SourceRefInfo>[];
    final List<Object?>? refs = _requireList(rule, 'sourceRefs', rulePath);
    if (refs != null) {
      for (int index = 0; index < refs.length; index++) {
        final String refPath = '$rulePath.sourceRefs[$index]';
        final Map<String, Object?>? ref = _asObject(refs[index], refPath);
        if (ref == null) {
          continue;
        }
        final _SourceRefInfo? info = _validateSourceRef(
          ref,
          refPath,
          includeReviewers: true,
        );
        if (info != null) {
          sourceRefs.add(info);
          if (family != null &&
              info.source != null &&
              !info.source!.ruleLayers.contains(family)) {
            _add(
              'sourceRef.layerMismatch',
              '$refPath.sourceId',
              'Source ${info.sourceId} is not registered for rule family $family.',
            );
          }
        }
      }
    }

    if (evidenceLevel != null && evidenceLevel != 'D' && sourceRefs.isEmpty) {
      _add(
        'evidence.sourceRequired',
        '$rulePath.sourceRefs',
        'A/B/C evidence requires at least one valid source reference; use D for an unsourced boundary.',
      );
    }

    if (locatorOnly == true && (evidenceLevel == 'A' || evidenceLevel == 'B')) {
      _add(
        'evidence.locatorPromotion',
        rulePath,
        'A locator-only rule cannot claim evidence level $evidenceLevel.',
      );
    }
    if (status == 'adopted' &&
        evidenceLevel != null &&
        evidenceLevel != 'A' &&
        evidenceLevel != 'B') {
      _add(
        'evidence.adoptedLevel',
        rulePath,
        'An adopted classic rule must have A or B evidence.',
      );
    }
    if (evidenceLevel == 'A' || evidenceLevel == 'B') {
      final List<_SourceRefInfo> scanRefs =
          sourceRefs.where((_SourceRefInfo ref) => ref.isUsableScan).toList();
      if (scanRefs.isEmpty) {
        _add(
          'evidence.scanRequired',
          '$rulePath.sourceRefs',
          'A/B evidence requires a stable locus in an image source.',
        );
      }
      if (!scanRefs.any((_SourceRefInfo ref) => ref.reviewerCount >= 2)) {
        _add(
          'evidence.secondReviewRequired',
          '$rulePath.sourceRefs',
          'A/B evidence requires two recorded page/quote reviewers.',
        );
      }
      if (evidenceLevel == 'A' &&
          scanRefs
                  .where((_SourceRefInfo ref) => ref.reviewerCount >= 2)
                  .map((_SourceRefInfo ref) => ref.sourceId)
                  .toSet()
                  .length <
              2) {
        _add(
          'evidence.aIndependentSource',
          '$rulePath.sourceRefs',
          'A evidence requires independently reviewed scan loci from two sources.',
        );
      }
    }
    if (executable == true) {
      if (status != 'adopted') {
        _add(
          'executable.status',
          rulePath,
          'Executable-approved rules must have adopted status.',
        );
      }
      if (evidenceLevel != 'A' && evidenceLevel != 'B') {
        _add(
          'executable.evidence',
          rulePath,
          'Executable-approved rules require A/B evidence.',
        );
      }
      if (locatorOnly == true) {
        _add(
          'executable.locator',
          rulePath,
          'A locator-only rule cannot be executable-approved.',
        );
      }
      if (fixtureIds.isEmpty) {
        _add(
          'executable.fixture',
          '$rulePath.fixtureIds',
          'Executable-approved rules require at least one independent fixture.',
        );
      }
      if (!sourceRefs.any((_SourceRefInfo ref) => ref.isUsableScan)) {
        _add(
          'executable.scan',
          '$rulePath.sourceRefs',
          'Executable-approved rules require a usable image locus.',
        );
      }
    }

    if (ruleId == null ||
        ordinal == null ||
        status == null ||
        evidenceLevel == null ||
        locatorOnly == null ||
        executable == null) {
      return null;
    }
    return _RuleInfo(
      ruleId: ruleId,
      family: documentFamily,
      ordinal: ordinal,
      status: status,
      evidenceLevel: evidenceLevel,
      locatorOnly: locatorOnly,
      executableApproved: executable,
      sourceRefs: sourceRefs,
      fixtureIds: fixtureIds,
      variantGroupId: variantGroupId,
      adoptedVariantId: adoptedVariantId,
    );
  }

  void _loadCases(Map<String, Object?> manifest) {
    final List<String> paths = _stringList(manifest['caseFiles']) ?? <String>[];
    for (final String relativePath in paths) {
      final Map<String, Object?>? document = _readRegistryObject(relativePath);
      if (document == null) {
        continue;
      }
      const Set<String> keys = <String>{
        'schemaVersion',
        'sourceWork',
        'catalogStatus',
        'limitations',
        'cases',
      };
      _requireExactKeys(document, keys, relativePath);
      _requireSchemaVersion(document, relativePath);
      final String? sourceWork =
          _requireContentString(document, 'sourceWork', relativePath);
      final String? catalogStatus = _requireEnum(
        document,
        'catalogStatus',
        <String>{'approved', 'partial', 'locatorOnly', 'sourceNotLocated'},
        relativePath,
      );
      _requireStringList(document, 'limitations', relativePath);
      if (catalogStatus == 'sourceNotLocated' && sourceWork != null) {
        _caseCatalogBlockers.add('$sourceWork: image source not located');
      }
      final List<Object?>? cases = _requireList(
        document,
        'cases',
        relativePath,
      );
      if (cases == null) {
        continue;
      }
      for (int index = 0; index < cases.length; index++) {
        final String casePath = '$relativePath.cases[$index]';
        final Map<String, Object?>? item = _asObject(cases[index], casePath);
        if (item == null) {
          continue;
        }
        final _CaseInfo? info = _validateCase(item, casePath);
        if (info == null) {
          continue;
        }
        if (_cases.containsKey(info.caseId)) {
          _add(
            'case.duplicate',
            '$casePath.caseId',
            'Duplicate caseId ${info.caseId}.',
          );
        } else {
          _cases[info.caseId] = info;
        }
      }
    }
  }

  _CaseInfo? _validateCase(Map<String, Object?> item, String casePath) {
    const Set<String> keys = <String>{
      'caseId',
      'title',
      'verificationStatus',
      'evidenceLevel',
      'locatorOnly',
      'sourceRef',
      'rawInput',
      'expectedFacts',
      'classicJudgment',
      'expectedDerivation',
      'unresolvedFields',
      'adoptedAssumptions',
      'coveredRuleIds',
      'targetCapabilityIds',
    };
    _requireExactKeys(item, keys, casePath);
    final String? caseId = _requirePatternString(
      item,
      'caseId',
      _caseIdPattern,
      casePath,
    );
    _requireContentString(item, 'title', casePath);
    final String? status = _requireEnum(
      item,
      'verificationStatus',
      _caseStatuses,
      casePath,
    );
    final String? evidenceLevel = _requireEnum(
      item,
      'evidenceLevel',
      _evidenceLevels,
      casePath,
    );
    final bool? locatorOnly = _requireBool(item, 'locatorOnly', casePath);
    _requireNonEmptyObject(item, 'rawInput', casePath);
    _requireNonEmptyObject(item, 'expectedFacts', casePath);
    _requireContentString(item, 'classicJudgment', casePath);
    _requireStringList(item, 'unresolvedFields', casePath);
    _requireStringList(item, 'adoptedAssumptions', casePath);
    final List<String> coveredRuleIds =
        _requireStringList(item, 'coveredRuleIds', casePath) ?? <String>[];
    _checkDuplicates(
      coveredRuleIds,
      'case.ruleDuplicate',
      '$casePath.coveredRuleIds',
    );
    _validatePatternValues(
      coveredRuleIds,
      _ruleIdPattern,
      '$casePath.coveredRuleIds',
    );
    final List<String>? targetCapabilityIds = _requireStringList(
      item,
      'targetCapabilityIds',
      casePath,
    );
    if (targetCapabilityIds != null && targetCapabilityIds.isEmpty) {
      _add(
        'shape.empty',
        '$casePath.targetCapabilityIds',
        'At least one target capability is required.',
      );
    }

    _SourceRefInfo? sourceRef;
    final Map<String, Object?>? sourceRefObject = _requireObject(
      item,
      'sourceRef',
      casePath,
    );
    if (sourceRefObject != null) {
      sourceRef = _validateSourceRef(
        sourceRefObject,
        '$casePath.sourceRef',
        includeReviewers: false,
      );
      if (sourceRef?.source != null &&
          !sourceRef!.source!.ruleLayers.contains('externalCases')) {
        _add(
          'sourceRef.layerMismatch',
          '$casePath.sourceRef.sourceId',
          'Source ${sourceRef.sourceId} is not registered for external cases.',
        );
      }
    }

    String? derivationMethod;
    bool? usesProductionCode;
    final Map<String, Object?>? derivation = _requireObject(
      item,
      'expectedDerivation',
      casePath,
    );
    if (derivation != null) {
      const Set<String> derivationKeys = <String>{
        'method',
        'usesProductionCode',
        'reviewer',
        'reviewedAt',
      };
      _requireExactKeys(
        derivation,
        derivationKeys,
        '$casePath.expectedDerivation',
      );
      derivationMethod = _requireEnum(
        derivation,
        'method',
        <String>{'independentManual', 'sourceTranscription', 'sourceScan'},
        '$casePath.expectedDerivation',
      );
      usesProductionCode = _requireBool(
        derivation,
        'usesProductionCode',
        '$casePath.expectedDerivation',
      );
      if (usesProductionCode == true) {
        _add(
          'case.productionExpected',
          '$casePath.expectedDerivation.usesProductionCode',
          'Expected facts must not be generated by production code.',
        );
      }
      _requireContentString(
        derivation,
        'reviewer',
        '$casePath.expectedDerivation',
      );
      _nullableDateField(
        derivation,
        'reviewedAt',
        '$casePath.expectedDerivation',
      );
    }

    if (locatorOnly == true && (evidenceLevel == 'A' || evidenceLevel == 'B')) {
      _add(
        'case.locatorPromotion',
        casePath,
        'A locator-only case cannot claim A/B evidence.',
      );
    }
    if (status == 'scanVerified' || status == 'approved') {
      if (evidenceLevel != 'A' && evidenceLevel != 'B') {
        _add(
          'case.approvedEvidence',
          casePath,
          'Scan-verified/approved cases require A/B evidence.',
        );
      }
      if (locatorOnly == true || sourceRef?.isUsableScan != true) {
        _add(
          'case.approvedScan',
          casePath,
          'Scan-verified/approved cases require a stable image locus.',
        );
      }
    }

    if (caseId == null ||
        status == null ||
        evidenceLevel == null ||
        locatorOnly == null ||
        sourceRef == null ||
        derivationMethod == null ||
        usesProductionCode == null) {
      return null;
    }
    return _CaseInfo(
      caseId: caseId,
      status: status,
      evidenceLevel: evidenceLevel,
      locatorOnly: locatorOnly,
      sourceRef: sourceRef,
      coveredRuleIds: coveredRuleIds,
      derivationMethod: derivationMethod,
      usesProductionCode: usesProductionCode,
    );
  }

  void _loadVariants(Map<String, Object?> manifest) {
    final String? variantPath = _string(manifest['variantFile']);
    if (variantPath == null) {
      return;
    }
    final Map<String, Object?>? document = _readRegistryObject(variantPath);
    if (document == null) {
      return;
    }
    const Set<String> keys = <String>{'schemaVersion', 'variants'};
    _requireExactKeys(document, keys, variantPath);
    _requireSchemaVersion(document, variantPath);
    final List<Object?>? variants = _requireList(
      document,
      'variants',
      variantPath,
    );
    if (variants == null) {
      return;
    }
    for (int index = 0; index < variants.length; index++) {
      final String variantPathEntry = '$variantPath.variants[$index]';
      final Map<String, Object?>? item = _asObject(
        variants[index],
        variantPathEntry,
      );
      if (item == null) {
        continue;
      }
      final _VariantInfo? info = _validateVariant(item, variantPathEntry);
      if (info == null) {
        continue;
      }
      if (_variants.containsKey(info.variantGroupId)) {
        _add(
          'variant.duplicate',
          '$variantPathEntry.variantGroupId',
          'Duplicate variantGroupId ${info.variantGroupId}.',
        );
      } else {
        _variants[info.variantGroupId] = info;
      }
    }
  }

  _VariantInfo? _validateVariant(
    Map<String, Object?> item,
    String variantPath,
  ) {
    const Set<String> keys = <String>{
      'variantGroupId',
      'topic',
      'affectedCapabilities',
      'impact',
      'status',
      'configurable',
      'adoptedVariantId',
      'adoptionRationale',
      'nonAdoptedDisplayStrategy',
      'blockingRuleIds',
      'options',
    };
    _requireExactKeys(item, keys, variantPath);
    final String? groupId = _requirePatternString(
      item,
      'variantGroupId',
      _variantGroupIdPattern,
      variantPath,
    );
    _requireContentString(item, 'topic', variantPath);
    final List<String>? affectedCapabilities = _requireStringList(
      item,
      'affectedCapabilities',
      variantPath,
    );
    if (affectedCapabilities != null && affectedCapabilities.isEmpty) {
      _add(
        'shape.empty',
        '$variantPath.affectedCapabilities',
        'At least one affected capability is required.',
      );
    }
    final List<String>? impacts = _requireStringList(
      item,
      'impact',
      variantPath,
    );
    if (impacts != null && impacts.isEmpty) {
      _add(
        'shape.empty',
        '$variantPath.impact',
        'At least one impact statement is required.',
      );
    }
    final String? status = _requireEnum(
      item,
      'status',
      _variantStatuses,
      variantPath,
    );
    final bool? configurable = _requireBool(item, 'configurable', variantPath);
    final String? adoptedVariantId = _nullableStringField(
      item,
      'adoptedVariantId',
      variantPath,
    );
    if (adoptedVariantId != null &&
        !_variantOptionIdPattern.hasMatch(adoptedVariantId)) {
      _add(
        'id.pattern',
        '$variantPath.adoptedVariantId',
        'Value does not match ${_variantOptionIdPattern.pattern}.',
      );
    }
    _requireContentString(item, 'adoptionRationale', variantPath);
    _requireContentString(
      item,
      'nonAdoptedDisplayStrategy',
      variantPath,
    );
    final List<String> blockingRuleIds =
        _requireStringList(item, 'blockingRuleIds', variantPath) ?? <String>[];
    _checkDuplicates(
      blockingRuleIds,
      'variant.ruleDuplicate',
      '$variantPath.blockingRuleIds',
    );
    _validatePatternValues(
      blockingRuleIds,
      _ruleIdPattern,
      '$variantPath.blockingRuleIds',
    );
    final List<Object?>? optionObjects = _requireList(
      item,
      'options',
      variantPath,
    );
    final Map<String, _VariantOptionInfo> options =
        <String, _VariantOptionInfo>{};
    if (optionObjects != null) {
      if (optionObjects.length < 2) {
        _add(
          'variant.optionCount',
          '$variantPath.options',
          'A variant decision requires at least two options.',
        );
      }
      for (int index = 0; index < optionObjects.length; index++) {
        final String optionPath = '$variantPath.options[$index]';
        final Map<String, Object?>? option = _asObject(
          optionObjects[index],
          optionPath,
        );
        if (option == null) {
          continue;
        }
        const Set<String> optionKeys = <String>{
          'variantId',
          'label',
          'evidenceLevel',
          'sourceRefs',
          'summary',
        };
        _requireExactKeys(option, optionKeys, optionPath);
        final String? variantId = _requirePatternString(
          option,
          'variantId',
          _variantOptionIdPattern,
          optionPath,
        );
        _requireContentString(option, 'label', optionPath);
        final String? evidenceLevel = _requireEnum(
          option,
          'evidenceLevel',
          _evidenceLevels,
          optionPath,
        );
        _requireContentString(option, 'summary', optionPath);
        final List<_SourceRefInfo> refs = <_SourceRefInfo>[];
        final List<Object?>? refObjects = _requireList(
          option,
          'sourceRefs',
          optionPath,
        );
        if (refObjects != null) {
          for (int refIndex = 0; refIndex < refObjects.length; refIndex++) {
            final String refPath = '$optionPath.sourceRefs[$refIndex]';
            final Map<String, Object?>? ref = _asObject(
              refObjects[refIndex],
              refPath,
            );
            if (ref == null) {
              continue;
            }
            final _SourceRefInfo? refInfo = _validateSourceRef(
              ref,
              refPath,
              includeReviewers: false,
            );
            if (refInfo != null) {
              refs.add(refInfo);
            }
          }
        }
        if (variantId != null && evidenceLevel != null) {
          if (options.containsKey(variantId)) {
            _add(
              'variant.optionDuplicate',
              '$optionPath.variantId',
              'Duplicate variantId $variantId.',
            );
          } else {
            options[variantId] = _VariantOptionInfo(
              evidenceLevel: evidenceLevel,
              sourceRefs: refs,
            );
          }
        }
      }
    }

    if (status == 'adopted' &&
        (adoptedVariantId == null || !options.containsKey(adoptedVariantId))) {
      _add(
        'variant.adoptedMissing',
        '$variantPath.adoptedVariantId',
        'An adopted decision must name one of its options.',
      );
    }
    if (adoptedVariantId != null && !options.containsKey(adoptedVariantId)) {
      _add(
        'variant.adoptedDangling',
        '$variantPath.adoptedVariantId',
        'adoptedVariantId $adoptedVariantId is not an option.',
      );
    }
    if (configurable == true) {
      if (status != 'adopted') {
        _add(
          'variant.configurableStatus',
          variantPath,
          'Only an adopted variant decision may be configurable.',
        );
      }
      for (final MapEntry<String, _VariantOptionInfo> option
          in options.entries) {
        final bool approvedLevel = option.value.evidenceLevel == 'A' ||
            option.value.evidenceLevel == 'B';
        final bool hasScan = option.value.sourceRefs
            .any((_SourceRefInfo ref) => ref.isUsableScan);
        if (!approvedLevel || !hasScan) {
          _add(
            'variant.configurableEvidence',
            '$variantPath.options.${option.key}',
            'Every configurable option requires A/B scan evidence.',
          );
        }
      }
    }

    if (groupId == null || status == null || configurable == null) {
      return null;
    }
    return _VariantInfo(
      variantGroupId: groupId,
      status: status,
      configurable: configurable,
      adoptedVariantId: adoptedVariantId,
      optionIds: options.keys.toSet(),
      blockingRuleIds: blockingRuleIds,
    );
  }

  _SourceRefInfo? _validateSourceRef(
    Map<String, Object?> ref,
    String refPath, {
    required bool includeReviewers,
  }) {
    final Set<String> keys = <String>{
      'sourceId',
      'referenceKind',
      'volume',
      'scanLeaf',
      'printedLeaf',
      'pdfPage',
      'imageLabel',
      'locator',
      'shortQuote',
      if (includeReviewers) 'verifiedBy',
    };
    _requireExactKeys(ref, keys, refPath);
    final String? sourceId = _requirePatternString(
      ref,
      'sourceId',
      _sourceIdPattern,
      refPath,
    );
    final String? referenceKind = _requireEnum(
      ref,
      'referenceKind',
      <String>{'scan', 'locator'},
      refPath,
    );
    final String? volume = _nullableStringField(ref, 'volume', refPath);
    final int? scanLeaf = _nullableNonNegativeInt(
      ref['scanLeaf'],
      '$refPath.scanLeaf',
    );
    final String? printedLeaf =
        _nullableStringField(ref, 'printedLeaf', refPath);
    final int? pdfPage = _nullablePositiveInt(
      ref['pdfPage'],
      '$refPath.pdfPage',
    );
    final String? imageLabel = _nullableStringField(ref, 'imageLabel', refPath);
    final String? locator = _nullableStringField(ref, 'locator', refPath);
    final String? shortQuote = _requireContentString(
      ref,
      'shortQuote',
      refPath,
    );
    if (shortQuote != null &&
        shortQuote.runes.length > _maxShortQuoteCharacters) {
      _add(
        'quote.tooLong',
        '$refPath.shortQuote',
        'Short quote has ${shortQuote.runes.length} characters; maximum is $_maxShortQuoteCharacters.',
      );
    }

    int reviewerCount = 0;
    if (includeReviewers) {
      final List<Object?>? reviewers = _requireList(ref, 'verifiedBy', refPath);
      if (reviewers != null) {
        final Set<String> reviewerIdentities = <String>{};
        for (int index = 0; index < reviewers.length; index++) {
          final String reviewerPath = '$refPath.verifiedBy[$index]';
          final Map<String, Object?>? reviewer = _asObject(
            reviewers[index],
            reviewerPath,
          );
          if (reviewer == null) {
            continue;
          }
          _requireExactKeys(
            reviewer,
            <String>{'reviewer', 'date'},
            reviewerPath,
          );
          final String? name =
              _requireContentString(reviewer, 'reviewer', reviewerPath);
          final String? date = _requireDate(reviewer, 'date', reviewerPath);
          if (name != null && date != null) {
            final String identity = name.trim().toLowerCase();
            if (!reviewerIdentities.add(identity)) {
              _add(
                'evidence.reviewerDuplicate',
                reviewerPath,
                'A reviewer identity may only count once per source locus.',
              );
            } else {
              reviewerCount++;
            }
          }
        }
      }
    }

    _SourceInfo? source;
    if (sourceId != null) {
      source = _sources[sourceId];
      if (source == null) {
        _add(
          'reference.sourceDangling',
          '$refPath.sourceId',
          'Unknown sourceId $sourceId.',
        );
      }
    }

    bool hasStableLocus = false;
    if (referenceKind == 'scan') {
      hasStableLocus = scanLeaf != null ||
          printedLeaf != null ||
          pdfPage != null ||
          imageLabel != null;
      if (!hasStableLocus) {
        _add(
          'sourceRef.locusMissing',
          refPath,
          'A scan reference needs scanLeaf, printedLeaf, pdfPage, or imageLabel.',
        );
      }
      if (volume == null) {
        _add(
          'sourceRef.volumeMissing',
          '$refPath.volume',
          'A scan reference must name a registered volume.',
        );
      } else if (source != null && !source.volumes.containsKey(volume)) {
        _add(
          'sourceRef.volumeDangling',
          '$refPath.volume',
          'Source ${source.sourceId} has no volume $volume.',
        );
      } else if (source != null) {
        final _VolumeInfo? volumeInfo = source.volumes[volume];
        if (volumeInfo != null) {
          if (scanLeaf != null && !volumeInfo.containsScanLeaf(scanLeaf)) {
            _add(
              'sourceRef.scanLeafRange',
              '$refPath.scanLeaf',
              'scanLeaf $scanLeaf is outside the registered volume range.',
            );
          }
          if (pdfPage != null && !volumeInfo.containsPdfPage(pdfPage)) {
            _add(
              'sourceRef.pdfPageRange',
              '$refPath.pdfPage',
              'pdfPage $pdfPage is outside the registered volume range.',
            );
          }
        }
      }
      if (source != null && source.sourceType != 'scan') {
        _add(
          'sourceRef.scanSourceType',
          '$refPath.sourceId',
          'A scan reference must point to a scan source.',
        );
      }
      if (source != null && source.locatorOnly) {
        _add(
          'sourceRef.scanSourceLocatorOnly',
          '$refPath.sourceId',
          'A locator-only source cannot support a scan reference.',
        );
      }
      if (source != null &&
          source.verificationStatus != 'scanVerified' &&
          source.verificationStatus != 'approved') {
        _add(
          'sourceRef.scanSourceUnverified',
          '$refPath.sourceId',
          'A scan reference requires a scanVerified or approved source.',
        );
      }
    } else if (referenceKind == 'locator') {
      if (locator == null) {
        _add(
          'sourceRef.locatorMissing',
          '$refPath.locator',
          'A locator reference must have a stable line/section locator.',
        );
      }
      if (scanLeaf != null ||
          printedLeaf != null ||
          pdfPage != null ||
          imageLabel != null) {
        _add(
          'sourceRef.locatorMixed',
          refPath,
          'Locator-only references must not masquerade as scan loci.',
        );
      }
    }

    if (sourceId == null || referenceKind == null) {
      return null;
    }
    return _SourceRefInfo(
      sourceId: sourceId,
      referenceKind: referenceKind,
      hasStableLocus: hasStableLocus,
      source: source,
      reviewerCount: reviewerCount,
    );
  }

  void _validateCrossReferences() {
    for (final _RuleInfo rule in _rules.values) {
      final List<_CaseInfo> referencedCases = <_CaseInfo>[];
      for (final String fixtureId in rule.fixtureIds) {
        final _CaseInfo? caseInfo = _cases[fixtureId];
        if (caseInfo == null) {
          _add(
            'reference.fixtureDangling',
            rule.ruleId,
            'Unknown fixtureId $fixtureId.',
          );
          continue;
        }
        referencedCases.add(caseInfo);
        if (!caseInfo.coveredRuleIds.contains(rule.ruleId)) {
          _add(
            'reference.fixtureCoverageMissing',
            rule.ruleId,
            'Fixture $fixtureId does not declare coverage of this rule.',
          );
        }
      }
      final bool hasIndependentEvidenceFixture = referencedCases.any(
        (_CaseInfo item) =>
            item.coveredRuleIds.contains(rule.ruleId) &&
            item.isIndependentEvidenceFixture,
      );
      if (rule.evidenceLevel == 'A' && !hasIndependentEvidenceFixture) {
        _add(
          'evidence.aFixture',
          rule.ruleId,
          'A evidence requires an approved A/B scan fixture with independently derived expected facts.',
        );
      }
      if (rule.executableApproved && !hasIndependentEvidenceFixture) {
        _add(
          'executable.fixtureEvidence',
          rule.ruleId,
          'Executable rules require an approved A/B scan fixture with independently derived expected facts.',
        );
      }
      final String? variantGroupId = rule.variantGroupId;
      if (variantGroupId != null) {
        final _VariantInfo? variant = _variants[variantGroupId];
        if (variant == null) {
          _add(
            'reference.variantDangling',
            rule.ruleId,
            'Unknown variantGroupId $variantGroupId.',
          );
        } else {
          final String? adoptedVariantId = rule.adoptedVariantId;
          if (adoptedVariantId != null &&
              !variant.optionIds.contains(adoptedVariantId)) {
            _add(
              'reference.variantOptionDangling',
              rule.ruleId,
              'Unknown adopted variant option $adoptedVariantId.',
            );
          }
          if (rule.executableApproved && variant.status != 'adopted') {
            _add(
              'executable.variantUnresolved',
              rule.ruleId,
              'Executable rules cannot depend on an unresolved variant decision.',
            );
          }
        }
      } else if (rule.adoptedVariantId != null) {
        _add(
          'reference.variantGroupMissing',
          rule.ruleId,
          'adoptedVariantId requires variantGroupId.',
        );
      }
    }

    for (final _CaseInfo caseInfo in _cases.values) {
      for (final String ruleId in caseInfo.coveredRuleIds) {
        if (!_rules.containsKey(ruleId)) {
          _add(
            'reference.ruleDangling',
            caseInfo.caseId,
            'Unknown covered ruleId $ruleId.',
          );
        }
      }
    }

    for (final _VariantInfo variant in _variants.values) {
      for (final String ruleId in variant.blockingRuleIds) {
        if (!_rules.containsKey(ruleId)) {
          _add(
            'reference.variantRuleDangling',
            variant.variantGroupId,
            'Unknown blocking ruleId $ruleId.',
          );
        }
      }
    }
  }

  void _validateFamilyConstraints() {
    for (final String family in _requiredFamilies) {
      if (!_families.containsKey(family)) {
        _add(
          'family.missing',
          'manifest.json.requiredFamilies',
          'Required family $family has no rule document.',
        );
      }
    }
    for (final MapEntry<String, int> constraint in _exactRuleCounts.entries) {
      final int actual = _families[constraint.key]?.length ?? 0;
      if (actual != constraint.value) {
        _add(
          'family.exactCount',
          'rules/${constraint.key}',
          'Expected exactly ${constraint.value} entries, found $actual.',
        );
      }
    }
  }

  String _buildCoverageMarkdown() {
    final StringBuffer buffer = StringBuffer()
      ..writeln('# 大六壬古籍证据覆盖报告')
      ..writeln()
      ..writeln('> 由 `tool/daliuren_classics/validate.dart` 从结构化证据目录生成。')
      ..writeln('> `pending`、`disputed` 与 locator-only 条目不计入已批准完成度。')
      ..writeln()
      ..writeln('## 汇总')
      ..writeln();

    final int totalRules = _rules.length;
    final int executableRules =
        _rules.values.where((_RuleInfo rule) => rule.executableApproved).length;
    final int nonExcludedRules = _rules.values
        .where((_RuleInfo rule) =>
            rule.status != 'excluded' && rule.status != 'deprecated')
        .length;
    final int approvedCases = _cases.values
        .where((_CaseInfo item) => item.status == 'approved')
        .length;
    final int locatorCases =
        _cases.values.where((_CaseInfo item) => item.locatorOnly).length;
    buffer
      ..writeln('- 规则总数：$totalRules')
      ..writeln('- 非排除规则：$nonExcludedRules')
      ..writeln('- 可执行批准规则：$executableRules')
      ..writeln('- 可执行批准完成度：$executableRules / $nonExcludedRules')
      ..writeln(
          '- 外部课例：${_cases.length}（A/B 批准 $approvedCases，locator-only $locatorCases）')
      ..writeln('- 已登记 source：${_sources.length}')
      ..writeln()
      ..writeln('## 规则族覆盖')
      ..writeln()
      ..writeln('| 规则族 | 总数 | 批准 | 待核 | 排除 | 争议 | Locator-only | 可执行 |')
      ..writeln('|---|---:|---:|---:|---:|---:|---:|---:|');

    final List<String> familyOrder = <String>[
      ..._requiredFamilies,
      ..._families.keys
          .where((String family) => !_requiredFamilies.contains(family)),
    ];
    for (final String family in familyOrder) {
      final List<_RuleInfo> rules = _families[family] ?? <_RuleInfo>[];
      final int adopted =
          rules.where((_RuleInfo rule) => rule.status == 'adopted').length;
      final int pending =
          rules.where((_RuleInfo rule) => rule.status == 'pending').length;
      final int excluded = rules
          .where((_RuleInfo rule) =>
              rule.status == 'excluded' || rule.status == 'deprecated')
          .length;
      final int disputed =
          rules.where((_RuleInfo rule) => rule.status == 'disputed').length;
      final int locator =
          rules.where((_RuleInfo rule) => rule.locatorOnly).length;
      final int executable =
          rules.where((_RuleInfo rule) => rule.executableApproved).length;
      buffer.writeln(
        '| $family | ${rules.length} | $adopted | $pending | $excluded | $disputed | $locator | $executable |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## 证据等级')
      ..writeln()
      ..writeln('| 等级 | 规则数 | 可执行批准 |')
      ..writeln('|---|---:|---:|');
    for (final String level in <String>['A', 'B', 'C', 'D']) {
      final List<_RuleInfo> rules = _rules.values
          .where((_RuleInfo rule) => rule.evidenceLevel == level)
          .toList();
      buffer.writeln(
        '| $level | ${rules.length} | ${rules.where((_RuleInfo rule) => rule.executableApproved).length} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## 外部课例')
      ..writeln()
      ..writeln('| Case ID | 状态 | 等级 | 影印页 |')
      ..writeln('|---|---|---|---|');
    for (final _CaseInfo item in _cases.values) {
      buffer.writeln(
        '| `${item.caseId}` | ${item.status} | ${item.evidenceLevel} | ${item.sourceRef.isUsableScan ? '有' : '无（locator-only）'} |',
      );
    }
    if (_cases.isEmpty) {
      buffer.writeln('| - | - | - | - |');
    }

    buffer
      ..writeln()
      ..writeln('## 未决异文')
      ..writeln();
    final List<_VariantInfo> unresolved = _variants.values
        .where((_VariantInfo item) => item.status != 'adopted')
        .toList();
    if (unresolved.isEmpty) {
      buffer.writeln('- 无。');
    } else {
      for (final _VariantInfo item in unresolved) {
        buffer.writeln(
          '- `${item.variantGroupId}`：${item.status}；configurable=${item.configurable}。',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('## 证据阻塞项')
      ..writeln();
    final List<String> blockers = <String>[];
    if (approvedCases < 2) {
      blockers.add('A/B 级页定位外部完整课例不足 2 张（当前 $approvedCases 张）。');
    }
    for (final String family in familyOrder) {
      final List<_RuleInfo> rules = _families[family] ?? <_RuleInfo>[];
      final int unapproved = rules
          .where((_RuleInfo rule) =>
              rule.status != 'adopted' &&
              rule.status != 'excluded' &&
              rule.status != 'deprecated')
          .length;
      if (unapproved > 0) {
        blockers.add('$family 尚有 $unapproved 条待核或争议规则。');
      }
    }
    for (final String title in _unregisteredSourceTitles) {
      blockers.add('$title 尚无可引用的稳定影印 source。');
    }
    blockers.addAll(_caseCatalogBlockers);
    if (blockers.isEmpty) {
      buffer.writeln('- 无。');
    } else {
      for (final String blocker in blockers.toSet()) {
        buffer.writeln('- $blocker');
      }
    }

    buffer
      ..writeln()
      ..writeln('## 校验边界')
      ..writeln()
      ..writeln('- 本报告只证明结构、引用与证据门禁状态，不判断古文解释是否正确。')
      ..writeln('- OCR 与固定转录只用于定位；未回到影印页的条目保持 C/D，且不可 `executableApproved`。')
      ..writeln('- 原书断语只作历史文本对照，不作为现实预测真实性验收。');
    return buffer.toString();
  }

  Map<String, Object?>? _readRegistryObject(String relativePath) {
    if (!_validateRelativePath(relativePath, 'manifest path')) {
      return null;
    }
    return _readObjectFile(
      File(p.join(registryRoot.path, p.normalize(relativePath))),
      relativePath,
    );
  }

  Map<String, Object?>? _readObjectFile(File file, String displayPath) {
    if (!file.existsSync()) {
      _add('path.missing', displayPath, 'Required JSON file does not exist.');
      return null;
    }
    Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync()) as Object?;
    } on FormatException catch (error) {
      _add('json.parse', displayPath, error.message);
      return null;
    }
    return _asObject(decoded, displayPath);
  }

  Map<String, Object?>? _asObject(Object? value, String path) {
    if (value is! Map<String, dynamic>) {
      _add('shape.object', path, 'Expected a JSON object.');
      return null;
    }
    return value.cast<String, Object?>();
  }

  Map<String, Object?>? _requireObject(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    if (!object.containsKey(key)) {
      _add('shape.required', '$path.$key', 'Required field is missing.');
      return null;
    }
    return _asObject(object[key], '$path.$key');
  }

  Map<String, Object?>? _requireNonEmptyObject(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final Map<String, Object?>? result = _requireObject(object, key, path);
    if (result != null && result.isEmpty) {
      _add('shape.empty', '$path.$key', 'Object must not be empty.');
    }
    return result;
  }

  List<Object?>? _requireList(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    if (!object.containsKey(key)) {
      _add('shape.required', '$path.$key', 'Required field is missing.');
      return null;
    }
    final Object? value = object[key];
    if (value is! List<dynamic>) {
      _add('shape.list', '$path.$key', 'Expected a JSON array.');
      return null;
    }
    return value.cast<Object?>();
  }

  String? _requireString(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    if (!object.containsKey(key)) {
      _add('shape.required', '$path.$key', 'Required field is missing.');
      return null;
    }
    final String? value = _string(object[key]);
    if (value == null || value.isEmpty) {
      _add('shape.string', '$path.$key', 'Expected a non-empty string.');
      return null;
    }
    return value;
  }

  String? _requireSchemaVersion(
    Map<String, Object?> object,
    String path,
  ) {
    final String? value = _requireString(object, 'schemaVersion', path);
    if (value != null && value != _supportedSchemaVersion) {
      _add(
        'schema.version',
        '$path.schemaVersion',
        'Expected schema version $_supportedSchemaVersion, found $value.',
      );
    }
    return value;
  }

  String? _requirePatternString(
    Map<String, Object?> object,
    String key,
    RegExp pattern,
    String path,
  ) {
    final String? value = _requireString(object, key, path);
    if (value != null && !pattern.hasMatch(value)) {
      _add(
        'id.pattern',
        '$path.$key',
        'Value does not match ${pattern.pattern}.',
      );
    }
    return value;
  }

  String? _requireContentString(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final String? value = _requireString(object, key, path);
    if (value != null) {
      if (value.trim().isEmpty) {
        _add(
          'content.blank',
          '$path.$key',
          'Required content must not be blank.',
        );
      }
      if (_placeholderPattern.hasMatch(value)) {
        _add(
          'content.placeholder',
          '$path.$key',
          'Required content contains a placeholder marker.',
        );
      }
    }
    return value;
  }

  String? _nullableStringField(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    if (!object.containsKey(key)) {
      _add('shape.required', '$path.$key', 'Required field is missing.');
      return null;
    }
    final Object? value = object[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.isEmpty) {
      _add(
          'shape.string', '$path.$key', 'Expected null or a non-empty string.');
      return null;
    }
    return value;
  }

  bool? _requireBool(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    if (!object.containsKey(key)) {
      _add('shape.required', '$path.$key', 'Required field is missing.');
      return null;
    }
    final Object? value = object[key];
    if (value is! bool) {
      _add('shape.type', '$path.$key', 'Expected a boolean.');
      return null;
    }
    return value;
  }

  int? _requirePositiveInt(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final Object? value = object[key];
    if (value is! int || value < 1) {
      _add('shape.type', '$path.$key', 'Expected a positive integer.');
      return null;
    }
    return value;
  }

  int? _requireNonNegativeInt(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final Object? value = object[key];
    if (value is! int || value < 0) {
      _add('shape.type', '$path.$key', 'Expected a non-negative integer.');
      return null;
    }
    return value;
  }

  int? _nullableNonNegativeInt(Object? value, String path) {
    if (value == null) {
      return null;
    }
    if (value is! int || value < 0) {
      _add('shape.type', path, 'Expected null or a non-negative integer.');
      return null;
    }
    return value;
  }

  int? _nullablePositiveInt(Object? value, String path) {
    if (value == null) {
      return null;
    }
    if (value is! int || value < 1) {
      _add('shape.type', path, 'Expected null or a positive integer.');
      return null;
    }
    return value;
  }

  List<String>? _requireStringList(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final List<Object?>? values = _requireList(object, key, path);
    if (values == null) {
      return null;
    }
    final List<String> result = <String>[];
    for (int index = 0; index < values.length; index++) {
      final Object? value = values[index];
      if (value is! String || value.isEmpty) {
        _add(
          'shape.string',
          '$path.$key[$index]',
          'Expected a non-empty string.',
        );
      } else {
        result.add(value);
      }
    }
    return result;
  }

  List<String>? _stringList(Object? value) {
    if (value is! List<dynamic>) {
      return null;
    }
    final List<String> result = <String>[];
    for (final Object? item in value.cast<Object?>()) {
      if (item is String) {
        result.add(item);
      }
    }
    return result;
  }

  String? _requireEnum(
    Map<String, Object?> object,
    String key,
    Set<String> allowed,
    String path,
  ) {
    final String? value = _requireString(object, key, path);
    if (value != null && !allowed.contains(value)) {
      _add(
        'enum.invalid',
        '$path.$key',
        'Expected one of ${allowed.join(', ')}, found $value.',
      );
      return null;
    }
    return value;
  }

  String? _requireDate(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final String? value = _requireString(object, key, path);
    if (value == null) {
      return null;
    }
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      _add('shape.date', '$path.$key', 'Expected an ISO-8601 calendar date.');
      return null;
    }
    return value;
  }

  String? _nullableDateField(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    if (!object.containsKey(key)) {
      _add('shape.required', '$path.$key', 'Required field is missing.');
      return null;
    }
    final Object? value = object[key];
    if (value == null) {
      return null;
    }
    if (value is! String ||
        DateTime.tryParse(value) == null ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      _add('shape.date', '$path.$key', 'Expected null or an ISO date.');
      return null;
    }
    return value;
  }

  String? _requireAbsoluteUri(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final String? value = _requireString(object, key, path);
    if (value == null) {
      return null;
    }
    final Uri? uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _add('shape.uri', '$path.$key', 'Expected an absolute URI.');
      return null;
    }
    return value;
  }

  String? _requireRelativePath(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final String? value = _requireString(object, key, path);
    if (value != null && !_validateRelativePath(value, '$path.$key')) {
      return null;
    }
    return value;
  }

  bool _validateRelativePath(String pathValue, String issuePath) {
    final String normalized = p.normalize(pathValue);
    if (p.isAbsolute(pathValue) ||
        normalized == '..' ||
        normalized.startsWith('..${p.separator}')) {
      _add(
        'path.invalid',
        issuePath,
        'Path must be relative and stay inside its declared root: $pathValue.',
      );
      return false;
    }
    return true;
  }

  void _requireExactKeys(
    Map<String, Object?> object,
    Set<String> expected,
    String path,
  ) {
    for (final String key in expected) {
      if (!object.containsKey(key)) {
        _add('shape.required', '$path.$key', 'Required field is missing.');
      }
    }
    for (final String key in object.keys) {
      if (!expected.contains(key)) {
        _add('shape.unknown', '$path.$key', 'Unknown field.');
      }
    }
  }

  void _checkDuplicates(
    List<String> values,
    String code,
    String path,
  ) {
    final Set<String> seen = <String>{};
    for (final String value in values) {
      if (!seen.add(value)) {
        _add(code, path, 'Duplicate value $value.');
      }
    }
  }

  void _validatePatternValues(
    List<String> values,
    RegExp pattern,
    String path,
  ) {
    for (int index = 0; index < values.length; index++) {
      if (!pattern.hasMatch(values[index])) {
        _add(
          'id.pattern',
          '$path[$index]',
          'Value does not match ${pattern.pattern}.',
        );
      }
    }
  }

  void _validateEnumValues(
    List<String> values,
    Set<String> allowed,
    String path,
  ) {
    for (int index = 0; index < values.length; index++) {
      if (!allowed.contains(values[index])) {
        _add(
          'enum.invalid',
          '$path[$index]',
          'Expected one of ${allowed.join(', ')}, found ${values[index]}.',
        );
      }
    }
  }

  void _validateRequiredPaths(
    List<String> actual,
    Set<String> required,
    String path,
  ) {
    for (final String requiredPath in required) {
      if (!actual.contains(requiredPath)) {
        _add(
          'manifest.requiredPathMissing',
          path,
          'Required registry path $requiredPath is missing.',
        );
      }
    }
  }

  String? _string(Object? value) => value is String ? value : null;

  void _add(String code, String path, String message) {
    _issues.add(ValidationIssue(code: code, path: path, message: message));
  }
}

class _SourceInfo {
  const _SourceInfo({
    required this.sourceId,
    required this.sourceType,
    required this.locatorOnly,
    required this.verificationStatus,
    required this.ruleLayers,
    required this.volumes,
  });

  final String sourceId;
  final String sourceType;
  final bool locatorOnly;
  final String verificationStatus;
  final Set<String> ruleLayers;
  final Map<String, _VolumeInfo> volumes;
}

class _VolumeInfo {
  const _VolumeInfo({
    required this.scanLeafBase,
    required this.leafCount,
    required this.pdfPageBase,
  });

  final int? scanLeafBase;
  final int? leafCount;
  final int? pdfPageBase;

  bool containsScanLeaf(int leaf) {
    if (scanLeafBase == null || leafCount == null) {
      return true;
    }
    return leaf >= scanLeafBase! && leaf < scanLeafBase! + leafCount!;
  }

  bool containsPdfPage(int page) {
    if (pdfPageBase == null || leafCount == null) {
      return true;
    }
    return page >= pdfPageBase! && page < pdfPageBase! + leafCount!;
  }
}

class _SourceRefInfo {
  const _SourceRefInfo({
    required this.sourceId,
    required this.referenceKind,
    required this.hasStableLocus,
    required this.source,
    required this.reviewerCount,
  });

  final String sourceId;
  final String referenceKind;
  final bool hasStableLocus;
  final _SourceInfo? source;
  final int reviewerCount;

  bool get isUsableScan =>
      referenceKind == 'scan' &&
      hasStableLocus &&
      source?.sourceType == 'scan' &&
      source?.locatorOnly == false &&
      (source?.verificationStatus == 'scanVerified' ||
          source?.verificationStatus == 'approved');
}

class _RuleInfo {
  const _RuleInfo({
    required this.ruleId,
    required this.family,
    required this.ordinal,
    required this.status,
    required this.evidenceLevel,
    required this.locatorOnly,
    required this.executableApproved,
    required this.sourceRefs,
    required this.fixtureIds,
    required this.variantGroupId,
    required this.adoptedVariantId,
  });

  final String ruleId;
  final String family;
  final int ordinal;
  final String status;
  final String evidenceLevel;
  final bool locatorOnly;
  final bool executableApproved;
  final List<_SourceRefInfo> sourceRefs;
  final List<String> fixtureIds;
  final String? variantGroupId;
  final String? adoptedVariantId;
}

class _CaseInfo {
  const _CaseInfo({
    required this.caseId,
    required this.status,
    required this.evidenceLevel,
    required this.locatorOnly,
    required this.sourceRef,
    required this.coveredRuleIds,
    required this.derivationMethod,
    required this.usesProductionCode,
  });

  final String caseId;
  final String status;
  final String evidenceLevel;
  final bool locatorOnly;
  final _SourceRefInfo sourceRef;
  final List<String> coveredRuleIds;
  final String derivationMethod;
  final bool usesProductionCode;

  bool get isIndependentEvidenceFixture =>
      status == 'approved' &&
      (evidenceLevel == 'A' || evidenceLevel == 'B') &&
      !locatorOnly &&
      sourceRef.isUsableScan &&
      derivationMethod == 'independentManual' &&
      !usesProductionCode;
}

class _VariantOptionInfo {
  const _VariantOptionInfo({
    required this.evidenceLevel,
    required this.sourceRefs,
  });

  final String evidenceLevel;
  final List<_SourceRefInfo> sourceRefs;
}

class _VariantInfo {
  const _VariantInfo({
    required this.variantGroupId,
    required this.status,
    required this.configurable,
    required this.adoptedVariantId,
    required this.optionIds,
    required this.blockingRuleIds,
  });

  final String variantGroupId;
  final String status;
  final bool configurable;
  final String? adoptedVariantId;
  final Set<String> optionIds;
  final List<String> blockingRuleIds;
}
