import 'dart:async';

import 'package:chat_kit/src/models/conversation.dart';
import 'package:chat_kit/src/services/chat_services.dart';
import 'package:flutter/foundation.dart';

/// Drives the conversations (home) screen: subscribes to the current user's
/// chats and exposes them sorted with most-recent activity first.
class ConversationListController extends ChangeNotifier {
  /// Subscribes to the current user's conversations via [services].
  ConversationListController(this.services) {
    _uid = services.auth.currentUid;
    _sub = services.chats
        .watchConversations(_uid)
        .listen(
          _onData,
          onError: _onError,
        );
  }

  /// Repository bundle this controller reads from.
  final ChatServices services;
  late final String _uid;
  StreamSubscription<List<Conversation>>? _sub;

  /// The current user's uid.
  String get currentUid => _uid;

  List<Conversation> _conversations = const [];

  /// The current user's conversations, most-recent activity first.
  List<Conversation> get conversations => _conversations;

  bool _loading = true;

  /// Whether the first batch of conversations is still loading.
  bool get loading => _loading;

  Object? _error;

  /// The last stream error, if any.
  Object? get error => _error;

  /// Total unread across all conversations — handy for a host-app badge.
  int get totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unreadFor(_uid));

  void _onData(List<Conversation> data) {
    _conversations = data;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  void _onError(Object error, StackTrace _) {
    _error = error;
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
