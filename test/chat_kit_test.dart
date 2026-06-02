import 'package:chat_kit/chat_kit.dart';
import 'package:chat_kit/src/utils/chat_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatId.direct', () {
    test('is deterministic regardless of argument order', () {
      expect(ChatId.direct('alice', 'bob'), ChatId.direct('bob', 'alice'));
    });

    test('produces distinct ids for distinct pairs', () {
      expect(
        ChatId.direct('alice', 'bob'),
        isNot(ChatId.direct('alice', 'carol')),
      );
    });

    test('is recognized by isDirect', () {
      final id = ChatId.direct('a', 'b');
      expect(ChatId.isDirect(id), isTrue);
      expect(ChatId.isDirect('group_xyz'), isFalse);
    });
  });

  group('ChatMessage.statusFor', () {
    ChatMessage msg({required Map<String, DateTime> readBy}) => ChatMessage(
      id: 'm1',
      senderId: 'me',
      type: MessageType.text,
      text: 'hi',
      timestamp: DateTime(2026),
      readBy: readBy,
    );

    test('sent when no other participant has read', () {
      final m = msg(readBy: {'me': DateTime(2026)});
      expect(m.statusFor(['me', 'a', 'b']), MessageStatus.sent);
    });

    test('delivered when some but not all have read', () {
      final m = msg(readBy: {'me': DateTime(2026), 'a': DateTime(2026)});
      expect(m.statusFor(['me', 'a', 'b']), MessageStatus.delivered);
    });

    test('read when all others have read', () {
      final m = msg(
        readBy: {
          'me': DateTime(2026),
          'a': DateTime(2026),
          'b': DateTime(2026),
        },
      );
      expect(m.statusFor(['me', 'a', 'b']), MessageStatus.read);
    });
  });
}
