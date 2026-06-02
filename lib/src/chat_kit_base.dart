import 'dart:async';

import 'package:chat_kit/src/config/chat_config.dart';
import 'package:chat_kit/src/services/chat_services.dart';
import 'package:chat_kit/src/ui/screens/chat_screen.dart';
import 'package:flutter/material.dart';

/// Entry point and lifecycle manager for the chat package.
///
/// Typical host usage, *after* `Firebase.initializeApp()` and a Firebase Auth
/// sign-in:
///
/// ```dart
/// ChatKit.configure(ChatConfig(
///   theme: ChatTheme.whatsapp(),
///   resolveUser: (uid) => myDirectory.user(uid),
///   fetchContacts: () => myDirectory.contacts(),
/// ));
/// await ChatKit.instance.startPresence();
/// // then navigate to ConversationsScreen()
/// ```
class ChatKit {
  ChatKit._(this.services);

  static ChatKit? _instance;

  /// The configured singleton. Throws if [configure] hasn't been called.
  static ChatKit get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'chat_kit: call ChatKit.configure(...) before using the chat '
        'UI.',
      );
    }
    return i;
  }

  /// Whether [configure] has been called.
  static bool get isConfigured => _instance != null;

  /// Configures the package with [config]. Safe to call again to swap config
  /// (e.g. theme change); rebuilds the underlying services.
  // ignore: prefer_constructors_over_static_methods  // intentional facade entry point
  static ChatKit configure(ChatConfig config) {
    _instance = ChatKit._(ChatServices(config: config));
    return _instance!;
  }

  /// The configured repositories backing the chat session.
  final ChatServices services;

  /// The active [ChatConfig] supplied to [configure].
  ChatConfig get config => services.config;

  /// Begins online/last-seen tracking for the signed-in user. Call once after
  /// sign-in (e.g. when first opening chat). No-op if presence is disabled.
  Future<void> startPresence() async {
    if (!config.enablePresence) return;
    await services.presence.start(services.auth.currentUid);
  }

  /// Marks the user offline and stops tracking. Call on sign-out.
  Future<void> stopPresence() async {
    if (!config.enablePresence) return;
    await services.presence.stop(services.auth.currentUid);
  }

  /// Registers this device for FCM push notifications: requests permission,
  /// stores the token, and wires foreground/tap handling. Call once after
  /// sign-in (alongside [startPresence]). No-op if push is disabled.
  ///
  /// Sending pushes requires the bundled Cloud Function (see `functions/`).
  Future<void> initPushNotifications() async {
    if (!config.enablePushNotifications) return;
    // Default tap routing: if the host gave us a navigatorKey but no explicit
    // callback, open the chat ourselves.
    services.push.onOpenChat ??=
        config.onNotificationTap ?? _openChatViaNavigator;
    await services.push.initialize(services.auth.currentUid);
  }

  /// Removes this device's push token. Call on sign-out.
  Future<void> stopPushNotifications() async {
    if (!config.enablePushNotifications) return;
    await services.push.dispose();
  }

  /// Tracks which chat is on screen so its foreground notifications are
  /// suppressed. Called by [ChatScreen]; rarely needed directly.
  // ignore: use_setters_to_change_properties  // reads as an imperative action
  void setActiveChat(String? chatId) => services.push.activeChatId = chatId;

  Future<void> _openChatViaNavigator(String chatId) async {
    final navigator = config.navigatorKey?.currentState;
    if (navigator == null) return;
    final convo = await services.chats.getConversation(chatId);
    if (convo == null) return;
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(conversation: convo),
        ),
      ),
    );
  }

  /// Tears down the singleton (e.g. on full sign-out). After this, [configure]
  /// must be called again before reuse.
  static Future<void> dispose() async {
    if (_instance != null) {
      await _instance!.stopPresence();
      await _instance!.stopPushNotifications();
      _instance = null;
    }
  }
}
