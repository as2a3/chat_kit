import 'package:chat_kit/src/models/chat_user.dart';
import 'package:chat_kit/src/services/firebase_refs.dart';

/// "typing…" indicators backed by the Realtime Database under
/// `typing/{chatId}/{uid}`. Entries auto-clear on disconnect.
class TypingRepository {
  /// Creates a [TypingRepository] backed by the given Firebase [refs].
  TypingRepository({required this.refs});

  /// Typed Firebase references used to read and write typing indicators.
  final FirebaseRefs refs;

  /// Marks [uid] as typing (or not) in [chatId]. When typing, registers an
  /// `onDisconnect` to clear the flag if the client drops.
  // ignore: avoid_positional_boolean_parameters  // public API signature
  Future<void> setTyping(String chatId, String uid, bool typing) async {
    final ref = refs.typingFor(chatId, uid);
    if (typing) {
      await ref.onDisconnect().remove();
      await ref.set(true);
    } else {
      await ref.remove();
    }
  }

  /// Live list of uids currently typing in [chatId], excluding [exclude]
  /// (normally the current user).
  Stream<List<String>> watch(String chatId, {String? exclude}) {
    return refs.typing(chatId).onValue.map((event) {
      final value = event.snapshot.value as Map<dynamic, dynamic>?;
      if (value == null) return const <String>[];
      return value.entries
          .where((e) => e.value == true && e.key != exclude)
          .map((e) => e.key as String)
          .toList();
    });
  }

  /// Resolve typing uids to display names via [resolve], for the subtitle.
  Future<List<ChatUser>> resolveTyping(
    List<String> uids,
    Future<ChatUser> Function(String) resolve,
  ) async {
    return Future.wait(uids.map(resolve));
  }
}
