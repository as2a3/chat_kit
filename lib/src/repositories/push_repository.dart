import 'dart:async';

import 'package:chat_kit/src/chat_kit_base.dart' show ChatKit;
import 'package:chat_kit/src/config/chat_config.dart';
import 'package:chat_kit/src/services/firebase_refs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background isolate handler. Must be a top-level (or static) function
/// annotated with `@pragma('vm:entry-point')`. With a `notification` payload
/// the OS draws the notification itself, so there's nothing to do here — but
/// FCM requires a registered handler for data delivery to work reliably.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally minimal: the system tray shows `notification` payloads while
  // backgrounded. Heavy work here would need its own Firebase.initializeApp().
}

/// FCM push-notification lifecycle for the chat package:
///  - requests permission and registers/refreshes the device token,
///  - shows a local notification for foreground messages (suppressing the chat
///    you're currently viewing),
///  - routes notification taps to the relevant chat.
///
/// Sending the actual push is the job of the bundled Cloud Function (see
/// `functions/`); this class only handles the device side.
// ignore: unreachable_from_main  // used by host app via the package facade
class PushRepository {
  /// Creates a [PushRepository] from the given Firebase [refs] and [config].
  // ignore: unreachable_from_main  // used by host app via the package facade
  PushRepository({required this.refs, required this.config});

  /// Typed Firebase references used to store device tokens.
  // ignore: unreachable_from_main  // used by host app via the package facade
  final FirebaseRefs refs;

  /// The chat configuration (notification-tap handling, etc.).
  // ignore: unreachable_from_main  // used by host app via the package facade
  final ChatConfig config;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'chat_kit_messages';
  static const _channelName = 'Chat messages';

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _currentUid;
  String? _token;

  /// Chat id currently open on screen; foreground notifications for it are
  /// suppressed. Set by [ChatKit.setActiveChat].
  // ignore: unreachable_from_main  // set by host app via the package facade
  String? activeChatId;

  /// Called when a notification (foreground tap or cold/background open) should
  /// open a chat. Defaults to [ChatConfig.onNotificationTap]; the facade may
  /// override it to drive [ChatConfig.navigatorKey].
  // ignore: unreachable_from_main  // set by host app via the package facade
  void Function(String chatId)? onOpenChat;

  bool _initialized = false;

  /// Requests permission, registers this device's token for [uid], wires up
  /// foreground/tap listeners and the local-notification channel. Safe to call
  /// once per signed-in session.
  // ignore: unreachable_from_main  // called by host app via the package facade
  Future<void> initialize(String uid) async {
    if (_initialized) return;
    _initialized = true;
    _currentUid = uid;
    onOpenChat ??= config.onNotificationTap;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // User declined — nothing more to set up, but keep state so a later
      // re-init is a no-op rather than re-prompting.
      return;
    }

    await _initLocalNotifications();
    await _registerToken(uid);

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      _token = token;
      unawaited(_saveToken(uid, token));
    });

    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForeground);
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
    );

    // App launched from a terminated state via a notification tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  Future<void> _initLocalNotifications() async {
    final android = AndroidInitializationSettings(
      config.androidNotificationIcon,
    );
    const darwin = DarwinInitializationSettings();
    await _local.initialize(
      settings: InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final chatId = response.payload;
        if (chatId != null && chatId.isNotEmpty) onOpenChat?.call(chatId);
      },
    );

    // Android requires an explicit channel for importance/sound.
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Notifications for new chat messages',
            importance: Importance.high,
          ),
        );
  }

  Future<void> _registerToken(String uid) async {
    // On Apple platforms FCM can't mint a token until APNs has handed the app
    // its device token, and that handshake completes asynchronously a moment
    // after launch — so getToken() throws if called too early. Wait for the
    // APNs token (getAPNSToken returns null, rather than throwing, while it's
    // still pending) before asking FCM for its token.
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final apnsToken = await _waitForApnsToken();
      // APNs never arrived (simulator, missing entitlement, etc.) — skip rather
      // than let getToken() throw and abort the rest of push setup.
      if (apnsToken == null) return;
    }

    final token = await _messaging.getToken();
    if (token == null) return;
    _token = token;
    await _saveToken(uid, token);
  }

  /// Polls for the APNs device token, which arrives asynchronously shortly
  /// after the app registers for remote notifications. Returns null if it
  /// hasn't appeared within a few seconds (e.g. on the iOS simulator, which
  /// can't receive one).
  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null) return apns;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  Future<void> _saveToken(String uid, String token) async {
    await refs.fcmTokens(uid).set({
      'tokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.name,
    }, SetOptions(merge: true));
  }

  void _handleForeground(RemoteMessage message) {
    final chatId = message.data['chatId'] as String?;
    // Don't notify for the chat the user is already looking at.
    if (chatId != null && chatId == activeChatId) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    unawaited(
      _local.show(
        id: chatId.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: chatId,
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final chatId = message.data['chatId'] as String?;
    if (chatId != null && chatId.isNotEmpty) onOpenChat?.call(chatId);
  }

  /// Removes this device's token (call on sign-out) and tears down listeners.
  // ignore: unreachable_from_main  // called by host app via the package facade
  Future<void> dispose() async {
    final uid = _currentUid;
    final token = _token;
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    if (uid != null && token != null) {
      await refs.fcmTokens(uid).set({
        'tokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    }
    _initialized = false;
    _currentUid = null;
    _token = null;
  }
}
