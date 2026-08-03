import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/model_transport.dart';
import '../../../tool/liuyao_ai_eval/security.dart';

void main() {
  test('judge transport sends the frozen JSON response and seed contract',
      () async {
    late Map<String, Object?> body;
    final OpenAiCompatibleEvalTransport transport =
        OpenAiCompatibleEvalTransport(
      client: MockClient((http.Request request) async {
        body = (jsonDecode(request.body) as Map).cast<String, Object?>();
        return http.Response(
          jsonEncode(<String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{'content': '{"ok":true}'},
              },
            ],
            'usage': <String, Object?>{'total_tokens': 12},
          }),
          200,
        );
      }),
    );

    final ModelCallResult result = await transport.call(
      credentials: const EvalCredentials(
        apiKey: 'test-secret-value',
        baseUrl: 'https://example.invalid/v1',
        model: 'exact-model-id',
        providerLabel: 'test',
      ),
      request: const ModelCallRequest(
        systemPrompt: 'judge system',
        userPrompt: 'judge input',
        temperature: 0,
        maxTokens: judgeMaxTokens,
        responseFormat: 'json',
        seed: judgeSeed,
      ),
    );

    expect(result.completed, isTrue);
    expect(body['model'], 'exact-model-id');
    expect(body['temperature'], 0);
    expect(body['max_completion_tokens'], judgeMaxTokens);
    expect(body['response_format'], <String, Object?>{'type': 'json_object'});
    expect(body['reasoning_effort'], evaluationReasoningEffort);
    expect(body['seed'], judgeSeed);
    expect(body['stream'], isFalse);
  });

  test('transport records deterministic seed capability fallback', () async {
    final List<Map<String, Object?>> bodies = <Map<String, Object?>>[];
    final OpenAiCompatibleEvalTransport transport =
        OpenAiCompatibleEvalTransport(
      client: MockClient((http.Request request) async {
        bodies.add((jsonDecode(request.body) as Map).cast<String, Object?>());
        if (bodies.length == 1) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'error': <String, Object?>{
                'message': "Unsupported parameter: 'seed'.",
                'type': 'invalid_request_error',
                'param': 'seed',
                'code': 'unsupported_parameter',
              },
            }),
            400,
          );
        }
        return http.Response(
          jsonEncode(<String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{'content': 'completed'},
              },
            ],
          }),
          200,
        );
      }),
    );

    final ModelCallResult result = await transport.call(
      credentials: const EvalCredentials(
        apiKey: 'test-secret-value',
        baseUrl: 'https://example.invalid/v1',
        model: 'exact-model-id',
        providerLabel: null,
      ),
      request: const ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: generationMaxTokens,
      ),
    );

    expect(result.completed, isTrue);
    expect(result.seedSupported, isFalse);
    expect(bodies, hasLength(2));
    expect(bodies.first['seed'], generationSeed);
    expect(bodies.last.containsKey('seed'), isFalse);
  });

  test('transport retries successful responses with empty model content',
      () async {
    int callCount = 0;
    final OpenAiCompatibleEvalTransport transport =
        OpenAiCompatibleEvalTransport(
      client: MockClient((http.Request request) async {
        callCount += 1;
        return http.Response(
          jsonEncode(<String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{
                  'content': callCount < 3 ? '   ' : 'completed after retry',
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await transport.call(
      credentials: const EvalCredentials(
        apiKey: 'test-secret-value',
        baseUrl: 'https://example.invalid/v1',
        model: 'exact-model-id',
        providerLabel: null,
      ),
      request: const ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: generationMaxTokens,
      ),
    );

    expect(result.completed, isTrue);
    expect(result.content, 'completed after retry');
    expect(result.retryCount, transportMaxRetryCount);
    expect(callCount, transportMaxRetryCount + 1);
  });

  test('transport retries empty HTTP bodies and null model content', () async {
    int callCount = 0;
    final OpenAiCompatibleEvalTransport transport =
        OpenAiCompatibleEvalTransport(
      client: MockClient((http.Request request) async {
        callCount += 1;
        if (callCount == 1) {
          return http.Response('', 200);
        }
        return http.Response(
          jsonEncode(<String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{
                  'content': callCount == 2 ? null : 'completed after retry',
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await transport.call(
      credentials: const EvalCredentials(
        apiKey: 'test-secret-value',
        baseUrl: 'https://example.invalid/v1',
        model: 'exact-model-id',
        providerLabel: null,
      ),
      request: const ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: generationMaxTokens,
      ),
    );

    expect(result.completed, isTrue);
    expect(result.content, 'completed after retry');
    expect(result.retryCount, transportMaxRetryCount);
    expect(callCount, transportMaxRetryCount + 1);
  });

  test(
      'transport fails closed when only reasoning content is returned repeatedly',
      () async {
    int callCount = 0;
    final OpenAiCompatibleEvalTransport transport =
        OpenAiCompatibleEvalTransport(
      client: MockClient((http.Request request) async {
        callCount += 1;
        return http.Response(
          jsonEncode(<String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{
                  'content': '',
                  'reasoning_content': 'not a user-visible final answer',
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await transport.call(
      credentials: const EvalCredentials(
        apiKey: 'test-secret-value',
        baseUrl: 'https://example.invalid/v1',
        model: 'exact-model-id',
        providerLabel: null,
      ),
      request: const ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: generationMaxTokens,
      ),
    );

    expect(result.completed, isFalse);
    expect(result.errorKind, 'emptyModelResponse');
    expect(result.statusCode, 200);
    expect(result.retryCount, transportMaxRetryCount);
    expect(callCount, transportMaxRetryCount + 1);
  });

  test('transport does not retry a non-empty malformed response', () async {
    int callCount = 0;
    final OpenAiCompatibleEvalTransport transport =
        OpenAiCompatibleEvalTransport(
      client: MockClient((http.Request request) async {
        callCount += 1;
        return http.Response('{}', 200);
      }),
    );

    final result = await transport.call(
      credentials: const EvalCredentials(
        apiKey: 'test-secret-value',
        baseUrl: 'https://example.invalid/v1',
        model: 'exact-model-id',
        providerLabel: null,
      ),
      request: const ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: generationMaxTokens,
      ),
    );

    expect(callCount, 1);
    expect(result.completed, isFalse);
    expect(result.errorKind, 'malformedResponse');
    expect(result.retryCount, 0);
  });

  test('transport does not drop seed for an unrelated bad request', () async {
    int callCount = 0;
    final OpenAiCompatibleEvalTransport transport =
        OpenAiCompatibleEvalTransport(
      client: MockClient((http.Request request) async {
        callCount += 1;
        return http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{
              'message': 'The seed field conflicts with another parameter.',
              'type': 'invalid_request_error',
              'param': 'temperature',
              'code': 'invalid_parameter',
            },
          }),
          400,
        );
      }),
    );

    final ModelCallResult result = await transport.call(
      credentials: const EvalCredentials(
        apiKey: 'test-secret-value',
        baseUrl: 'https://example.invalid/v1',
        model: 'exact-model-id',
        providerLabel: null,
      ),
      request: const ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: generationMaxTokens,
      ),
    );

    expect(callCount, 1);
    expect(result.completed, isFalse);
    expect(result.seedSupported, isNull);
    expect(result.errorKind, 'remoteRequestRejected');
  });

  test('transport rejects non-frozen requests before HTTP', () async {
    int callCount = 0;
    final OpenAiCompatibleEvalTransport transport =
        OpenAiCompatibleEvalTransport(
      client: MockClient((http.Request request) async {
        callCount += 1;
        return http.Response('{}', 200);
      }),
    );
    const EvalCredentials credentials = EvalCredentials(
      apiKey: 'test-secret-value',
      baseUrl: 'https://example.invalid/v1',
      model: 'exact-model-id',
      providerLabel: null,
    );
    const List<ModelCallRequest> invalidRequests = <ModelCallRequest>[
      ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0.1,
        maxTokens: generationMaxTokens,
      ),
      ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: generationMaxTokens + 1,
      ),
      ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: generationMaxTokens,
        responseFormat: 'xml',
      ),
      ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: generationMaxTokens,
        seed: generationSeed + 1,
      ),
      ModelCallRequest(
        systemPrompt: 'system',
        userPrompt: 'input',
        temperature: 0,
        maxTokens: judgeMaxTokens,
        responseFormat: 'json',
        seed: judgeSeed + 1,
      ),
    ];

    for (final ModelCallRequest request in invalidRequests) {
      await expectLater(
        transport.call(credentials: credentials, request: request),
        throwsA(
          isA<EvalFailure>().having(
            (EvalFailure error) => error.kind,
            'kind',
            'invalidModelCallRequest',
          ),
        ),
      );
    }
    expect(callCount, 0);
  });
}
