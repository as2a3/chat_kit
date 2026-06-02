import 'package:chat_kit/src/models/chat_message.dart';
import 'package:chat_kit/src/services/firebase_refs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads and writes messages within a chat, and keeps the parent chat doc's
/// `lastMessage` / `unreadCounts` / `updatedAt` in sync.
class MessageRepository {
  /// Creates a [MessageRepository] backed by the given Firebase [refs].
  MessageRepository({required this.refs});

  /// Typed Firebase references used to read and write message documents.
  final FirebaseRefs refs;

  /// Streams the most recent [limit] messages, newest first (so a reversed
  /// `ListView` renders them bottom-up like WhatsApp).
  Stream<List<ChatMessage>> watchMessages(String chatId, {int limit = 30}) {
    return refs
        .messages(chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  /// One page of older messages before [before] (for pagination). Returns them
  /// newest-first to match [watchMessages].
  Future<List<ChatMessage>> loadOlder(
    String chatId, {
    required DateTime before,
    int limit = 30,
  }) async {
    final snap = await refs
        .messages(chatId)
        .orderBy('timestamp', descending: true)
        .startAfter([Timestamp.fromDate(before)])
        .limit(limit)
        .get();
    return snap.docs.map(ChatMessage.fromDoc).toList();
  }

  /// Sends [message] and atomically updates the chat doc: bumps `updatedAt`,
  /// writes the `lastMessage` preview, and increments every *other*
  /// participant's unread counter.
  Future<void> send(String chatId, ChatMessage message) async {
    final batch = refs.firestore.batch();
    final msgRef = refs.messages(chatId).doc(message.id);
    batch.set(msgRef, message.toCreateMap());

    final chatSnap = await refs.chat(chatId).get();
    final participants = List<String>.from(
      chatSnap.data()?['participants'] as List? ?? const [],
    );

    final chatUpdate = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': {
        'text': message.preview,
        'senderId': message.senderId,
        'type': message.type.name,
        'timestamp': FieldValue.serverTimestamp(),
      },
      // A new message un-hides the chat for anyone who had deleted it.
      'clearedBy': <String>[],
    };
    for (final uid in participants) {
      if (uid != message.senderId) {
        chatUpdate['unreadCounts.$uid'] = FieldValue.increment(1);
      }
    }
    batch.update(refs.chat(chatId), chatUpdate);
    await batch.commit();
  }

  /// Marks every message in [messageIds] as read by [uid] (stamps `readBy`) and
  /// resets [uid]'s unread counter on the chat doc. No-op when [messageIds] is
  /// empty.
  Future<void> markRead(
    String chatId,
    String uid,
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return;
    final batch = refs.firestore.batch();
    for (final id in messageIds) {
      batch.set(
        refs.messages(chatId).doc(id),
        {
          'readBy': {uid: FieldValue.serverTimestamp()},
        },
        SetOptions(merge: true),
      );
    }
    batch.set(
      refs.chat(chatId),
      {
        'unreadCounts': {uid: 0},
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Deletes a message (hard delete). Callers should check permissions first.
  Future<void> delete(String chatId, String messageId) =>
      refs.messages(chatId).doc(messageId).delete();

  /// A fresh message id, used so the sender can render an optimistic bubble
  /// before the server round-trip completes.
  String newId(String chatId) => refs.messages(chatId).doc().id;
}
