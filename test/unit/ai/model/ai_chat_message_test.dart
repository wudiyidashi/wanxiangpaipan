import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/model/ai_chat_message.dart';

void main() {
  group('AIChatMessage', () {
    test('round-trip json serialization preserves all fields', () {
      final msg = AIChatMessage(
        id: 'm1',
        role: ChatRole.assistant,
        content: 'hello',
        timestamp: DateTime.utc(2026, 4, 23, 12, 0, 0),
        status: ChatMessageStatus.sent,
      );

      final json = msg.toJson();
      final restored = AIChatMessage.fromJson(json);

      expect(restored, equals(msg));
    });

    test('serializes errorMessage when failed', () {
      final msg = AIChatMessage(
        id: 'm2',
        role: ChatRole.user,
        content: 'try again',
        timestamp: DateTime.utc(2026, 4, 23),
        status: ChatMessageStatus.failed,
        errorMessage: 'network error',
      );

      final json = msg.toJson();

      expect(json['errorMessage'], 'network error');
      expect(json['status'], 'failed');
    });
  });
}
