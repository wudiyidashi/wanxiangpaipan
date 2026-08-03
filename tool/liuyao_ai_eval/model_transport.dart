import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'security.dart';

class ModelCallRequest {
  const ModelCallRequest({
    required this.systemPrompt,
    required this.userPrompt,
    required this.temperature,
    required this.maxTokens,
    this.responseFormat = 'text',
    this.seed = generationSeed,
  });

  final String systemPrompt;
  final String userPrompt;
  final double temperature;
  final int maxTokens;
  final String responseFormat;
  final int seed;
}

class ModelCallResult {
  const ModelCallResult({
    required this.completed,
    required this.content,
    required this.tokensUsed,
    required this.latencyMilliseconds,
    required this.seedSupported,
    required this.errorKind,
    required this.statusCode,
    required this.retryCount,
  });

  final bool completed;
  final String? content;
  final int? tokensUsed;
  final int latencyMilliseconds;
  final bool? seedSupported;
  final String? errorKind;
  final int? statusCode;
  final int retryCount;
}

abstract class EvalModelTransport {
  Future<ModelCallResult> call({
    required EvalCredentials credentials,
    required ModelCallRequest request,
  });
}

class OpenAiCompatibleEvalTransport implements EvalModelTransport {
  OpenAiCompatibleEvalTransport({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<ModelCallResult> call({
    required EvalCredentials credentials,
    required ModelCallRequest request,
  }) async {
    final bool isJsonResponse = request.responseFormat == 'json';
    final int expectedMaxTokens =
        isJsonResponse ? judgeMaxTokens : generationMaxTokens;
    if (!<String>{'text', 'json'}.contains(request.responseFormat) ||
        request.temperature != 0 ||
        request.maxTokens != expectedMaxTokens ||
        (request.responseFormat == 'json'
            ? request.seed != judgeSeed
            : request.seed != generationSeed)) {
      throw const EvalFailure('invalidModelCallRequest');
    }
    final Stopwatch stopwatch = Stopwatch()..start();
    bool includeSeed = true;
    int retryCount = 0;
    while (true) {
      http.Response response;
      try {
        response = await _client
            .post(
              _completionUri(credentials.baseUrl),
              headers: <String, String>{
                'Authorization': 'Bearer ${credentials.apiKey}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(<String, Object?>{
                'model': credentials.model,
                'messages': <Object?>[
                  <String, Object?>{
                    'role': 'system',
                    'content': request.systemPrompt,
                  },
                  <String, Object?>{
                    'role': 'user',
                    'content': request.userPrompt,
                  },
                ],
                'temperature': request.temperature,
                'max_completion_tokens': request.maxTokens,
                'stream': false,
                'response_format': <String, Object?>{
                  'type':
                      request.responseFormat == 'json' ? 'json_object' : 'text',
                },
                'reasoning_effort': evaluationReasoningEffort,
                'stop': <Object?>[],
                if (includeSeed) 'seed': request.seed,
              }),
            )
            .timeout(Duration(seconds: credentials.timeoutSeconds));
      } on TimeoutException {
        if (retryCount < transportMaxRetryCount) {
          retryCount += 1;
          continue;
        }
        stopwatch.stop();
        return ModelCallResult(
          completed: false,
          content: null,
          tokensUsed: null,
          latencyMilliseconds: stopwatch.elapsedMilliseconds,
          seedSupported: includeSeed ? null : false,
          errorKind: 'transportTimeout',
          statusCode: null,
          retryCount: retryCount,
        );
      } on http.ClientException {
        if (retryCount < transportMaxRetryCount) {
          retryCount += 1;
          continue;
        }
        stopwatch.stop();
        return ModelCallResult(
          completed: false,
          content: null,
          tokensUsed: null,
          latencyMilliseconds: stopwatch.elapsedMilliseconds,
          seedSupported: includeSeed ? null : false,
          errorKind: 'transportConnection',
          statusCode: null,
          retryCount: retryCount,
        );
      }

      if (includeSeed && _isUnsupportedSeedResponse(response)) {
        includeSeed = false;
        continue;
      }
      if ((response.statusCode == 429 || response.statusCode >= 500) &&
          retryCount < transportMaxRetryCount) {
        retryCount += 1;
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        stopwatch.stop();
        return ModelCallResult(
          completed: false,
          content: null,
          tokensUsed: null,
          latencyMilliseconds: stopwatch.elapsedMilliseconds,
          seedSupported: includeSeed ? null : false,
          errorKind: _httpErrorKind(response.statusCode),
          statusCode: response.statusCode,
          retryCount: retryCount,
        );
      }

      try {
        final Object? decoded =
            response.body.trim().isEmpty ? null : jsonDecode(response.body);
        if (decoded == null) {
          throw const _EmptyModelResponse();
        }
        final Map<String, Object?> body =
            (decoded as Map).cast<String, Object?>();
        final List<Object?> choices =
            (body['choices']! as List).cast<Object?>();
        final Map<String, Object?> choice =
            (choices.first as Map).cast<String, Object?>();
        final Map<String, Object?> message =
            (choice['message']! as Map).cast<String, Object?>();
        final Object? rawContent = message['content'];
        if (rawContent == null ||
            (rawContent is String && rawContent.trim().isEmpty)) {
          throw const _EmptyModelResponse();
        }
        final String content = rawContent as String;
        final Object? usageRaw = body['usage'];
        final int tokens = usageRaw is Map
            ? ((usageRaw.cast<String, Object?>()['total_tokens'] as int?) ?? 0)
            : 0;
        stopwatch.stop();
        return ModelCallResult(
          completed: true,
          content: content,
          tokensUsed: tokens,
          latencyMilliseconds: stopwatch.elapsedMilliseconds,
          seedSupported: includeSeed,
          errorKind: null,
          statusCode: response.statusCode,
          retryCount: retryCount,
        );
      } on _EmptyModelResponse {
        if (retryCount < transportMaxRetryCount) {
          retryCount += 1;
          continue;
        }
        stopwatch.stop();
        return ModelCallResult(
          completed: false,
          content: null,
          tokensUsed: null,
          latencyMilliseconds: stopwatch.elapsedMilliseconds,
          seedSupported: includeSeed,
          errorKind: 'emptyModelResponse',
          statusCode: response.statusCode,
          retryCount: retryCount,
        );
      } on Object {
        stopwatch.stop();
        return ModelCallResult(
          completed: false,
          content: null,
          tokensUsed: null,
          latencyMilliseconds: stopwatch.elapsedMilliseconds,
          seedSupported: includeSeed,
          errorKind: 'malformedResponse',
          statusCode: response.statusCode,
          retryCount: retryCount,
        );
      }
    }
  }

  Uri _completionUri(String baseUrl) {
    final Uri base = Uri.parse(baseUrl);
    if (base.path.endsWith('/chat/completions')) {
      return base;
    }
    final String path = base.path.endsWith('/') ? base.path : '${base.path}/';
    return base.replace(path: '${path}chat/completions');
  }

  bool _isUnsupportedSeedResponse(http.Response response) {
    if (response.statusCode != 400) {
      return false;
    }
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return false;
      }
      final Object? errorRaw = decoded['error'];
      if (errorRaw is! Map) {
        return false;
      }
      final Map<String, Object?> error = errorRaw.cast<String, Object?>();
      if (error['param'] != 'seed') {
        return false;
      }
      final Object? code = error['code'];
      if (code == 'unsupported_parameter') {
        return true;
      }
      final Object? message = error['message'];
      return message is String &&
          RegExp(
            r'\b(?:unsupported|not supported)\b',
            caseSensitive: false,
          ).hasMatch(message);
    } on Object {
      return false;
    }
  }

  String _httpErrorKind(int statusCode) => switch (statusCode) {
        401 || 403 => 'authenticationRejected',
        404 => 'endpointOrModelNotFound',
        429 => 'rateLimitExhausted',
        >= 500 => 'remoteServerFailure',
        _ => 'remoteRequestRejected',
      };
}

class _EmptyModelResponse implements Exception {
  const _EmptyModelResponse();
}
