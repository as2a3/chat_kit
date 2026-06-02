import 'package:chat_kit/src/models/chat_user.dart';
import 'package:chat_kit/src/models/conversation.dart';
import 'package:chat_kit/src/repositories/message_repository.dart'
    show MessageRepository;
import 'package:chat_kit/src/services/firebase_refs.dart';
import 'package:chat_kit/src/utils/chat_id.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation-level operations: listing chats, creating/finding direct chats,
/// creating and managing groups. Message content lives in [MessageRepository].
class ChatRepository {
  /// Creates a [ChatRepository] backed by the given Firebase [refs].
  ChatRepository({required this.refs});

  /// Typed Firebase references used to read and write chat documents.
  final FirebaseRefs refs;

  /// Live stream of [me]'s conversations, most-recently-active first. Chats the
  /// user has deleted (in `clearedBy`) are filtered out client-side — Firestore
  /// can't express "array does not contain" server-side.
  Stream<List<Conversation>> watchConversations(String me) {
    return refs.chats
        .where('participants', arrayContains: me)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(Conversation.fromDoc)
              .where((c) => !c.isClearedFor(me))
              .toList(),
        );
  }

  /// Live stream of the single conversation [chatId].
  Stream<Conversation> watchConversation(String chatId) {
    return refs.chat(chatId).snapshots().map(Conversation.fromDoc);
  }

  /// One-shot read of conversation [chatId], or `null` if it doesn't exist.
  Future<Conversation?> getConversation(String chatId) async {
    final doc = await refs.chat(chatId).get();
    return doc.exists ? Conversation.fromDoc(doc) : null;
  }

  /// Returns the existing direct chat between [me] and [other], creating it if
  /// it doesn't exist. The id is deterministic ([ChatId.direct]) so concurrent
  /// creates from both peers converge on the same doc.
  Future<Conversation> openDirectChat({
    required ChatUser me,
    required ChatUser other,
  }) async {
    final id = ChatId.direct(me.id, other.id);
    final ref = refs.chat(id);
    final snap = await ref.get();
    if (snap.exists) return Conversation.fromDoc(snap);

    await ref.set({
      'type': 'direct',
      'participants': [me.id, other.id],
      'participantInfo': {
        me.id: me.toInfoMap(),
        other.id: other.toInfoMap(),
      },
      'admins': <String>[],
      'createdBy': me.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts': {me.id: 0, other.id: 0},
    }, SetOptions(merge: true));

    return Conversation.fromDoc(await ref.get());
  }

  /// Creates a group chat with [members] (the creator is added automatically as
  /// the first admin). Returns the new conversation id.
  Future<String> createGroup({
    required ChatUser creator,
    required List<ChatUser> members,
    required String name,
    String? photoUrl,
  }) async {
    final everyone = <String, ChatUser>{creator.id: creator};
    for (final m in members) {
      everyone[m.id] = m;
    }

    final ref = refs.chats.doc();
    await ref.set({
      'type': 'group',
      'name': name,
      'photoUrl': ?photoUrl,
      'participants': everyone.keys.toList(),
      'participantInfo': {
        for (final u in everyone.values) u.id: u.toInfoMap(),
      },
      'admins': [creator.id],
      'createdBy': creator.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts': {for (final id in everyone.keys) id: 0},
    });
    return ref.id;
  }

  /// Adds [members] to [chatId], updating participants, info and unread counts.
  Future<void> addMembers(String chatId, List<ChatUser> members) async {
    final ref = refs.chat(chatId);
    await refs.firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final participants = List<String>.from(
        data['participants'] as List? ?? [],
      );
      final info = Map<String, dynamic>.from(
        data['participantInfo'] as Map? ?? {},
      );
      final unread = Map<String, dynamic>.from(
        data['unreadCounts'] as Map? ?? {},
      );
      for (final m in members) {
        if (!participants.contains(m.id)) participants.add(m.id);
        info[m.id] = m.toInfoMap();
        unread[m.id] ??= 0;
      }
      tx.update(ref, {
        'participants': participants,
        'participantInfo': info,
        'unreadCounts': unread,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Removes [uid] from [chatId], clearing their participant/unread entries.
  Future<void> removeMember(String chatId, String uid) async {
    await refs.chat(chatId).update({
      'participants': FieldValue.arrayRemove([uid]),
      'admins': FieldValue.arrayRemove([uid]),
      'participantInfo.$uid': FieldValue.delete(),
      'unreadCounts.$uid': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Grants ([isAdmin] = true) or revokes admin rights for [uid] in [chatId].
  // ignore: avoid_positional_boolean_parameters  // public API signature
  Future<void> setAdmin(String chatId, String uid, bool isAdmin) async {
    await refs.chat(chatId).update({
      'admins': isAdmin
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Renames group [chatId] to [name].
  Future<void> renameGroup(String chatId, String name) async {
    await refs.chat(chatId).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Current user leaves the group.
  Future<void> leaveGroup(String chatId, String uid) =>
      removeMember(chatId, uid);

  /// Mutes ([muted] = true) or unmutes push notifications for [uid] in
  /// [chatId]. Toggles the user's own entry in the chat's `mutedBy` array.
  // ignore: avoid_positional_boolean_parameters  // public API signature
  Future<void> setMuted(String chatId, String uid, bool muted) async {
    await refs.chat(chatId).set({
      'mutedBy': muted
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    }, SetOptions(merge: true));
  }

  /// Hides [chatId] from [uid]'s conversation list and resets their unread
  /// count. This is a per-user delete — the chat (and its messages) stay intact
  /// for other participants, and it reappears for [uid] when a new message
  /// arrives. Use [leaveGroup] to actually leave a group.
  Future<void> deleteChatForUser(String chatId, String uid) async {
    await refs.chat(chatId).set({
      'clearedBy': FieldValue.arrayUnion([uid]),
      'unreadCounts': {uid: 0},
    }, SetOptions(merge: true));
  }

  /// Clears [uid]'s unread badge for [chatId] without opening the thread. Does
  /// not stamp per-message read receipts (those are set when the chat is
  /// actually viewed).
  Future<void> markConversationRead(String chatId, String uid) async {
    await refs.chat(chatId).set({
      'unreadCounts': {uid: 0},
    }, SetOptions(merge: true));
  }
}
