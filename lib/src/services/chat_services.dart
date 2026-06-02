import 'package:chat_kit/src/chat_kit_base.dart' show ChatKit;
import 'package:chat_kit/src/config/chat_config.dart';
import 'package:chat_kit/src/repositories/auth_repository.dart';
import 'package:chat_kit/src/repositories/chat_repository.dart';
import 'package:chat_kit/src/repositories/media_repository.dart';
import 'package:chat_kit/src/repositories/message_repository.dart';
import 'package:chat_kit/src/repositories/presence_repository.dart';
import 'package:chat_kit/src/repositories/push_repository.dart';
import 'package:chat_kit/src/repositories/typing_repository.dart';
import 'package:chat_kit/src/services/firebase_refs.dart';

/// Bundles the configured repositories so screens and controllers can reach
/// them through a single object. Built once by the [ChatKit] facade and
/// shared for the lifetime of the chat session.
class ChatServices {
  /// Creates the repository bundle from [config], optionally reusing existing
  /// Firebase handles via [refs].
  ChatServices({required this.config, FirebaseRefs? refs})
    : refs = refs ?? FirebaseRefs() {
    auth = AuthRepository(config: config);
    chats = ChatRepository(refs: this.refs);
    messages = MessageRepository(refs: this.refs);
    presence = PresenceRepository(refs: this.refs);
    typing = TypingRepository(refs: this.refs);
    media = MediaRepository(refs: this.refs, config: config);
    push = PushRepository(refs: this.refs, config: config);
  }

  /// Host-supplied configuration for the chat package.
  final ChatConfig config;

  /// Shared Firebase handles used by every repository.
  final FirebaseRefs refs;

  /// Resolves the current user and host-supplied user info.
  late final AuthRepository auth;

  /// Reads and writes chat (conversation) documents.
  late final ChatRepository chats;

  /// Reads and writes messages within a chat.
  late final MessageRepository messages;

  /// Tracks online/last-seen presence.
  late final PresenceRepository presence;

  /// Tracks "typing…" indicators.
  late final TypingRepository typing;

  /// Uploads and downloads chat media.
  late final MediaRepository media;

  /// Manages FCM tokens and push notifications.
  late final PushRepository push;
}
