import 'package:path/path.dart' as p;

const String evalToolSchemaVersion = 'liuyao-ai-eval-tool/1.0.0';
const String evalFixtureVersion = 'liuyao-ai-eval-fixture/1.0.0';
const String evalRubricVersion = 'liuyao-ai-rubric/1.0.0';
const String evalRequestSchemaVersion = 'liuyao-ai-request-set/1.0.0';
const String evalArtifactSchemaVersion = 'liuyao-ai-eval-artifact/1.0.0';
const String evalCanonicalAdapterSchemaVersion =
    'liuyao-ai-canonical-adapter/1.0.0';
const String evalOfflineComparisonSchemaVersion =
    'liuyao-ai-offline-comparison/1.0.0';
const String evalPairedRunSchemaVersion = 'liuyao-ai-paired-run/1.2.0';
const String evalJudgeRequestSchemaVersion = 'liuyao-ai-judge-request/1.0.0';
const String evalJudgeResponseSchemaVersion = 'liuyao-ai-judge-response/1.0.0';
const String realWorldAdapterSchemaVersion = 'liuyao-real-world-adapter/1.0.0';
const String realWorldJudgeReferenceManifestSchemaVersion =
    'liuyao-real-world-judge-reference-manifest/1.0.0';
const String realWorldJudgeResponseSchemaVersion =
    'liuyao-real-world-judge-response/1.1.0';
const String realWorldRunSchemaVersion = 'liuyao-real-world-run/1.3.0';
const String candidatePromptPolicyRevision = '1.1.20';
const String candidatePromptPolicyVersion =
    'liuyao-ai-policy/$candidatePromptPolicyRevision';
const String transportRetryPolicyVersion = 'liuyao-ai-transport-retry/1.2.0';
const String evaluationReasoningEffort = 'none';
const int transportMaxRetryCount = 2;
const String holdoutSelectionSalt = 'liuyao-holdout-v1-2026-08-01';
const String generationOrderSalt = 'liuyao-pair-order-v1';
const String judgeOrderSalt = 'liuyao-judge-order-v1';
const int generationSeed = 424242;
const int judgeSeed = 271828;
const int generationMaxTokens = 2048;
const int judgeMaxTokens = 2048;
const int generationInputUtf8ByteLimit = 128 * 1024;
const int judgeInputUtf8ByteLimit = 256 * 1024;
const int defaultTransportTimeoutSeconds = 240;
const int minimumTransportTimeoutSeconds = 30;
const int maximumTransportTimeoutSeconds = 600;

const String canonicalProjectionSchemaVersion = '1';
const String canonicalRuleSetId = 'liuyao-zengshan-primary';
const String canonicalRuleSetVersion = 'v2';
const String canonicalV2FixtureHash =
    '24299a942e5ed77c808a58bc5657ac55a695ef8db6fdd352949c93aa41ae040a';
const String canonicalV2AdapterHash =
    '6a15a33d92ed54a576b8f2f7242e746d36887e6bca26ff900f91d37cb9de13c1';
const String canonicalV2CandidateHash =
    '6cea01d796e401c493ea5c5693c22af44ba00be80b5cf86ba7c4554286652959';
const String legacyDiagnosticVariant = 'legacy-e2e-diagnostic';
const String baselineVariant = 'canonical-v2-baseline';
const String candidateVariant = 'canonical-v2-candidate';

const String evalLocalConfigRelativePath =
    'tool/liuyao_ai_eval/eval.local.json';
const String evalLocalConfigIgnoreRule = '/tool/liuyao_ai_eval/eval.local.json';
const String evalCanonicalAdapterRelativePath =
    'tool/liuyao_ai_eval/fixtures/canonical_v2_adapter.json';
const String evalCanonicalFixtureRelativePath =
    'tool/liuyao_ai_eval/fixtures/canonical_v2_fixture.json';
const String evalClassicsFixtureRelativePath =
    'test/fixtures/liuyao/classics_cases.v1.json';
const String realWorldGenerationFixtureRelativePath =
    'tool/liuyao_ai_eval/fixtures/real_world_rental_generation.json';
const String realWorldJudgeReferenceRelativePath =
    'tool/liuyao_ai_eval/fixtures/real_world_rental_reference.json';
const String realWorldJudgeReferenceManifestRelativePath =
    'tool/liuyao_ai_eval/fixtures/real_world_rental_reference_manifest.json';
const String realWorldBaselineRequestsRelativePath =
    'tool/liuyao_ai_eval/frozen/actual_rental_v160_requests.json';
const String realWorldAdapterRelativePath =
    'tool/liuyao_ai_eval/fixtures/real_world_rental_adapter.json';
const String evalOutputRootRelativePath = '.tmp/liuyao_ai_eval';

const Set<String> supportedVariants = <String>{
  legacyDiagnosticVariant,
  baselineVariant,
  candidateVariant,
};

const Set<String> supportedRealModelStatuses = <String>{
  'ready',
  'blockedMissingCredentials',
  'blockedInvalidConfiguration',
  'failedTransport',
  'completed',
};

String toolPath(String repositoryRoot, String relativePath) =>
    p.normalize(p.join(repositoryRoot, relativePath));
