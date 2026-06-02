import 'package:chat_kit/src/models/message_status.dart';
import 'package:chat_kit/src/models/message_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message inside `chats/{chatId}/messages/{messageId}`.
class ChatMessage {
  /// Creates a chat message.
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    this.text = '',
    this.mediaUrl,
    this.mediaThumbUrl,
    this.fileName,
    this.fileSize,
    this.durationMs,
    this.timestamp,
    this.readBy = const {},
    this.replyToId,
    this.replyToPreview,
  });

  /// Builds a [ChatMessage] from a Firestore message document.
  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final rawReadBy = (data['readBy'] as Map<String, dynamic>?) ?? const {};
    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      type: MessageType.fromName(data['type'] as String?),
      text: (data['text'] as String?) ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaThumbUrl: data['mediaThumbUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: (data['fileSize'] as num?)?.toInt(),
      durationMs: (data['durationMs'] as num?)?.toInt(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      readBy: rawReadBy.map(
        (uid, ts) => MapEntry(
          uid,
          ts is Timestamp
              ? ts.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ),
      replyToId: data['replyToId'] as String?,
      replyToPreview: data['replyToPreview'] as String?,
    );
  }

  /// Unique message id within the chat.
  final String id;

  /// Uid of the message author.
  final String senderId;

  /// The kind of content this message carries.
  final MessageType type;

  /// Text body (empty for non-text messages).
  final String text;

  /// Download URL for [MessageType.isMedia] messages.
  final String? mediaUrl;

  /// Download URL for a media thumbnail, if any.
  final String? mediaThumbUrl;

  /// Original file name for [MessageType.file] messages.
  final String? fileName;

  /// File size in bytes for [MessageType.file] messages.
  final int? fileSize;

  /// Audio/video duration in milliseconds.
  final int? durationMs;

  /// Server send time. Null while the write is still pending locally.
  final DateTime? timestamp;

  /// Map of `uid -> read time`. Used to derive [MessageStatus] and receipts.
  final Map<String, DateTime> readBy;

  /// Id of the message this one replies to, if any.
  final String? replyToId;

  /// Cached preview text of the replied-to message, if any.
  final String? replyToPreview;

  /// Whether the message is still awaiting its server timestamp.
  bool get isPending => timestamp == null;

  /// Whether [uid] has read this message.
  bool isReadBy(String uid) => readBy.containsKey(uid);

  /// Derives the sender-facing [MessageStatus] given the other participants.
  ///
  /// [otherParticipants] should exclude the sender. A message is
  /// [MessageStatus.read] once every other participant appears in [readBy];
  /// [MessageStatus.delivered] once at least one has; otherwise
  /// [MessageStatus.sent].
  MessageStatus statusFor(Iterable<String> otherParticipants) {
    final others = otherParticipants.where((u) => u != senderId).toList();
    if (others.isEmpty) return MessageStatus.sent;
    final readCount = others.where(readBy.containsKey).length;
    if (readCount >= others.length) return MessageStatus.read;
    if (readCount > 0) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  /// Payload for a *new* message. `timestamp` and `readBy[sender]` use
  /// [FieldValue.serverTimestamp] so the server stamps them.
  Map<String, dynamic> toCreateMap() => {
    'senderId': senderId,
    'type': type.name,
    'text': text,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
    if (mediaThumbUrl != null) 'mediaThumbUrl': mediaThumbUrl,
    if (fileName != null) 'fileName': fileName,
    if (fileSize != null) 'fileSize': fileSize,
    if (durationMs != null) 'durationMs': durationMs,
    if (replyToId != null) 'replyToId': replyToId,
    if (replyToPreview != null) 'replyToPreview': replyToPreview,
    'timestamp': FieldValue.serverTimestamp(),
    'readBy': {senderId: FieldValue.serverTimestamp()},
  };

  /// A short single-line summary used for the conversation list and replies.
  String get preview {
    switch (type) {
      case MessageType.text:
        return text;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎤 Voice message';
      case MessageType.file:
        return '📎 ${fileName ?? 'File'}';
      case MessageType.system:
        return text;
    }
  }
}
