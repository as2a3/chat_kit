import 'dart:async';

import 'package:chat_kit/src/models/chat_message.dart';
import 'package:chat_kit/src/models/conversation.dart';
import 'package:chat_kit/src/models/message_type.dart';
import 'package:chat_kit/src/models/presence.dart';
import 'package:chat_kit/src/repositories/media_repository.dart';
import 'package:chat_kit/src/services/chat_services.dart';
import 'package:chat_kit/src/ui/screens/chat_screen.dart' show ChatScreen;
import 'package:flutter/foundation.dart';

/// Drives a single chat thread ([ChatScreen]): streams messages, sends text and
/// media, manages the typing indicator (with debounce), auto-marks incoming
/// messages as read, and tracks the peer's presence + typing state.
class ChatController extends ChangeNotifier {
  /// Streams and drives the [conversation] thread using [services].
  ChatController({required this.services, required this.conversation}) {
    _uid = services.auth.currentUid;
    _subscribe();
  }

  /// Repository bundle this controller reads from and writes to.
  final ChatServices services;

  /// The conversation this controller drives.
  final Conversation conversation;
  late final String _uid;

  /// Id of the chat being displayed.
  String get chatId => conversation.id;

  /// The current user's uid.
  String get currentUid => _uid;

  // --- Messages ----------------------------------------------------------

  List<ChatMessage> _messages = const [];

  /// Messages in the thread, oldest first.
  List<ChatMessage> get messages => _messages;

  bool _loading = true;

  /// Whether the first batch of messages is still loading.
  bool get loading => _loading;

  StreamSubscription<List<ChatMessage>>? _msgSub;
  StreamSubscription<List<String>>? _typingSub;
  final Map<String, StreamSubscription<Presence>> _presenceSubs = {};

  // --- Typing & presence -------------------------------------------------

  List<String> _typingUids = const [];

  /// Uids (other than the current user) currently typing.
  List<String> get typingUids => _typingUids;

  /// Whether anyone other than the current user is typing.
  bool get someoneTyping => _typingUids.isNotEmpty;

  final Map<String, Presence> _presence = {};

  /// Presence for [uid], defaulting to offline if unknown.
  Presence presenceOf(String uid) => _presence[uid] ?? Presence.offline;

  /// Peer presence for a direct chat (null for groups).
  Presence? get peerPresence {
    final other = conversation.otherParticipant(_uid);
    return other == null ? null : presenceOf(other);
  }

  bool _isTypingLocal = false;
  Timer? _typingTimer;

  /// In-flight media uploads keyed by optimistic message id → progress 0..1.
  final Map<String, double> _uploads = {};

  /// In-flight upload progress (0..1) keyed by optimistic message id.
  Map<String, double> get uploads => Map.unmodifiable(_uploads);

  void _subscribe() {
    _msgSub = services.messages.watchMessages(chatId).listen((data) {
      _messages = data;
      _loading = false;
      notifyListeners();
      _markVisibleRead();
    });

    if (services.config.enableTypingIndicators) {
      _typingSub = services.typing.watch(chatId, exclude: _uid).listen((uids) {
        _typingUids = uids;
        notifyListeners();
      });
    }

    if (services.config.enablePresence) {
      for (final uid in conversation.participants) {
        if (uid == _uid) continue;
        _presenceSubs[uid] = services.presence.watch(uid).listen((p) {
          _presence[uid] = p;
          notifyListeners();
        });
      }
    }
  }

  // --- Sending -----------------------------------------------------------

  /// Sends a text message after trimming; no-op if [text] is blank.
  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _setTyping(false);
    final message = ChatMessage(
      id: services.messages.newId(chatId),
      senderId: _uid,
      type: MessageType.text,
      text: trimmed,
    );
    await services.messages.send(chatId, message);
  }

  /// Uploads [picked] then sends a media message. Surfaces upload progress via
  /// [uploads] keyed by the message id.
  Future<void> sendMedia(PickedMedia picked, {String caption = ''}) async {
    final messageId = services.messages.newId(chatId);
    _uploads[messageId] = 0;
    notifyListeners();
    try {
      final uploaded = await services.media.upload(
        chatId: chatId,
        messageId: messageId,
        media: picked,
        onProgress: (p) {
          _uploads[messageId] = p;
          notifyListeners();
        },
      );
      final message = ChatMessage(
        id: messageId,
        senderId: _uid,
        type: uploaded.type,
        text: caption,
        mediaUrl: uploaded.url,
        fileName: uploaded.fileName,
        fileSize: uploaded.fileSize,
      );
      await services.messages.send(chatId, message);
    } finally {
      _uploads.remove(messageId);
      notifyListeners();
    }
  }

  // --- Typing indicator --------------------------------------------------

  /// Call on every keystroke. Broadcasts "typing" and auto-clears it ~3s after
  /// the last keystroke (debounced) so we don't spam RTDB.
  void onUserTyping() {
    if (!services.config.enableTypingIndicators) return;
    unawaited(_setTyping(true));
    _typingTimer?.cancel();
    _typingTimer = Timer(
      const Duration(seconds: 3),
      () => unawaited(_setTyping(false)),
    );
  }

  Future<void> _setTyping(bool typing) async {
    if (!services.config.enableTypingIndicators) return;
    if (_isTypingLocal == typing) return;
    _isTypingLocal = typing;
    if (!typing) _typingTimer?.cancel();
    await services.typing.setTyping(chatId, _uid, typing);
  }

  // --- Read receipts -----------------------------------------------------

  void _markVisibleRead() {
    final unread = _messages
        .where((m) => m.senderId != _uid && !m.isReadBy(_uid) && !m.isPending)
        .map((m) => m.id)
        .toList();
    if (unread.isEmpty) return;
    // Fire-and-forget; failures are non-critical and will retry on next stream
    // tick.
    unawaited(services.messages.markRead(chatId, _uid, unread));
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    unawaited(_msgSub?.cancel());
    unawaited(_typingSub?.cancel());
    for (final sub in _presenceSubs.values) {
      unawaited(sub.cancel());
    }
    // Best-effort clear of our typing flag when leaving the screen.
    if (services.config.enableTypingIndicators && _isTypingLocal) {
      unawaited(services.typing.setTyping(chatId, _uid, false));
    }
    super.dispose();
  }
}
