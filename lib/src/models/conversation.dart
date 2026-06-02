import 'package:chat_kit/src/models/chat_user.dart';
import 'package:chat_kit/src/models/message_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether a [Conversation] is a 1-on-1 chat or a group.
enum ConversationType {
  /// A 1-on-1 chat between exactly two participants.
  direct,

  /// A group chat with two or more participants.
  group,
}

/// A compact view of `lastMessage` stored on the chat doc, so the conversation
/// list can render without reading the messages subcollection.
class LastMessagePreview {
  /// Creates a last-message preview.
  const LastMessagePreview({
    required this.text,
    required this.senderId,
    required this.type,
    this.timestamp,
  });

  /// Builds a preview from the `lastMessage` map on a chat doc.
  factory LastMessagePreview.fromMap(Map<String, dynamic> map) {
    return LastMessagePreview(
      text: (map['text'] as String?) ?? '',
      senderId: (map['senderId'] as String?) ?? '',
      type: MessageType.fromName(map['type'] as String?),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  /// Preview text of the last message.
  final String text;

  /// Uid of the last message's sender.
  final String senderId;

  /// The kind of content the last message carried.
  final MessageType type;

  /// Server send time of the last message, if known.
  final DateTime? timestamp;
}

/// A chat thread: either a 1-on-1 [ConversationType.direct] chat or a
/// [ConversationType.group]. Backed by `chats/{id}`.
class Conversation {
  /// Creates a conversation.
  const Conversation({
    required this.id,
    required this.type,
    required this.participants,
    required this.participantInfo,
    this.name,
    this.photoUrl,
    this.admins = const [],
    this.createdBy,
    this.createdAt,
    this.lastMessage,
    this.unreadCounts = const {},
    this.mutedBy = const [],
    this.clearedBy = const [],
  });

  /// Builds a [Conversation] from a Firestore chat document.
  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final rawInfo =
        (data['participantInfo'] as Map<String, dynamic>?) ?? const {};
    final rawUnread =
        (data['unreadCounts'] as Map<String, dynamic>?) ?? const {};
    return Conversation(
      id: doc.id,
      type: (data['type'] == 'group')
          ? ConversationType.group
          : ConversationType.direct,
      participants: List<String>.from(
        data['participants'] as List? ?? const [],
      ),
      participantInfo: rawInfo.map(
        (uid, info) => MapEntry(
          uid,
          ChatUser.fromMap(uid, Map<String, dynamic>.from(info as Map)),
        ),
      ),
      name: data['name'] as String?,
      photoUrl: data['photoUrl'] as String?,
      admins: List<String>.from(data['admins'] as List? ?? const []),
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastMessage: data['lastMessage'] is Map
          ? LastMessagePreview.fromMap(
              Map<String, dynamic>.from(data['lastMessage'] as Map),
            )
          : null,
      unreadCounts: rawUnread.map((k, v) => MapEntry(k, (v as num).toInt())),
      mutedBy: List<String>.from(data['mutedBy'] as List? ?? const []),
      clearedBy: List<String>.from(data['clearedBy'] as List? ?? const []),
    );
  }

  /// Chat document id.
  final String id;

  /// Whether this is a direct or group chat.
  final ConversationType type;

  /// Uids of all participants.
  final List<String> participants;

  /// `uid -> ChatUser` denormalized snapshot for fast list rendering.
  final Map<String, ChatUser> participantInfo;

  /// Group name (null for direct chats — derive the title from the other peer).
  final String? name;

  /// Group avatar url (null for direct chats).
  final String? photoUrl;

  /// Uids with admin privileges in a group chat.
  final List<String> admins;

  /// Uid of the user who created the chat, if known.
  final String? createdBy;

  /// Time the chat was created, if known.
  final DateTime? createdAt;

  /// Preview of the most recent message, if any.
  final LastMessagePreview? lastMessage;

  /// `uid -> unread message count`.
  final Map<String, int> unreadCounts;

  /// Uids that have muted notifications for this chat. Muting only suppresses
  /// pushes; unread counts are unaffected.
  final List<String> mutedBy;

  /// Uids that have deleted (hidden) this chat from their list. The chat
  /// reappears for a user once a new message arrives (the sender clears this
  /// list when sending).
  final List<String> clearedBy;

  /// Whether this is a group chat.
  bool get isGroup => type == ConversationType.group;

  /// Unread message count for [uid].
  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  /// Whether [uid] has muted notifications for this chat.
  bool isMutedFor(String uid) => mutedBy.contains(uid);

  /// Whether [uid] has hidden this chat from their list.
  bool isClearedFor(String uid) => clearedBy.contains(uid);

  /// Whether [uid] is an admin of this (group) chat.
  bool isAdmin(String uid) => admins.contains(uid);

  /// The other participant's uid in a direct chat (relative to [me]).
  String? otherParticipant(String me) {
    if (isGroup) return null;
    return participants.firstWhere((u) => u != me, orElse: () => me);
  }

  /// Title to show for this conversation from [me]'s perspective: the group
  /// name, or the other peer's display name for direct chats.
  String titleFor(String me) {
    if (isGroup) return name ?? 'Group';
    final other = otherParticipant(me);
    return participantInfo[other]?.name ?? 'Chat';
  }

  /// Avatar url to show from [me]'s perspective.
  String? avatarFor(String me) {
    if (isGroup) return photoUrl;
    return participantInfo[otherParticipant(me)]?.photoUrl;
  }
}
