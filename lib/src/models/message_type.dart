import 'package:chat_kit/src/models/chat_message.dart' show ChatMessage;

/// The kind of content a [ChatMessage] carries.
enum MessageType {
  /// A plain text message.
  text,

  /// An image message.
  image,

  /// A video message.
  video,

  /// An audio/voice message.
  audio,

  /// A file attachment message.
  file,

  /// A system-generated message (e.g. membership changes).
  system;

  /// Parses a stored string value back into a [MessageType], defaulting to
  /// [MessageType.text] for unknown/legacy values.
  static MessageType fromName(String? value) {
    return MessageType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => MessageType.text,
    );
  }

  /// Whether this type carries a downloadable media payload.
  bool get isMedia =>
      this == image || this == video || this == audio || this == file;
}
