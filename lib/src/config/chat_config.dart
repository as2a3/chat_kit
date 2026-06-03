import 'package:chat_kit/src/models/chat_user.dart';
import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:flutter/widgets.dart';

/// Resolve a single user's display info by uid. Return `null` if unknown.
typedef ResolveUser = Future<ChatUser?> Function(String uid);

/// Provide the set of users the current user is allowed to start a chat with
/// (your app's contacts/directory). Used by the "new chat" screen.
typedef FetchContacts = Future<List<ChatUser>> Function();

/// Host-supplied configuration for the chat package.
///
/// The package never owns your user directory — it asks for users through
/// [resolveUser] and [fetchContacts]. Both are optional: without them the
/// package falls back to whatever info is denormalized on chat docs, and the
/// "new chat" screen will be empty.
class ChatConfig {
  /// Creates a chat configuration. All parameters are optional; [theme]
  /// defaults to the WhatsApp-style theme.
  ChatConfig({
    ChatTheme? theme,
    this.resolveUser,
    this.fetchContacts,
    this.enablePresence = true,
    this.enableTypingIndicators = true,
    this.enablePushNotifications = true,
    this.databaseUrl,
    this.onNotificationTap,
    this.navigatorKey,
    this.maxMediaBytes = 25 * 1024 * 1024,
    this.androidNotificationIcon = '@mipmap/ic_launcher',
  }) : theme = theme ?? ChatTheme.whatsapp();

  /// Visual theme used across the chat UI.
  final ChatTheme theme;

  /// Resolves a user's display info by uid, or null if not provided.
  final ResolveUser? resolveUser;

  /// Supplies the contacts available for starting a new chat, or null.
  final FetchContacts? fetchContacts;

  /// Track and display online/last-seen state via the Realtime Database.
  final bool enablePresence;

  /// Show and broadcast "typing…" indicators via the Realtime Database.
  final bool enableTypingIndicators;

  /// Explicit Realtime Database URL, e.g.
  /// `https://my-app-default-rtdb.europe-west1.firebasedatabase.app`.
  ///
  /// Required whenever your RTDB instance lives outside the default
  /// `us-central1` region (or isn't present in your generated Firebase
  /// options): in that case the default `FirebaseDatabase.instance` has no URL
  /// and presence/typing silently do nothing. Find it in the Firebase console
  /// under Realtime Database → Data. Leave null only if your default Firebase
  /// options already carry the database URL.
  final String? databaseUrl;

  /// Register for FCM push notifications and surface foreground messages.
  /// Requires deploying the bundled Cloud Function to actually send pushes.
  final bool enablePushNotifications;

  /// Called with the target chat id when a notification is tapped. If null and
  /// [navigatorKey] is provided, the package opens the chat itself.
  final void Function(String chatId)? onNotificationTap;

  /// When provided (and [onNotificationTap] is null), the package uses this to
  /// navigate to the tapped chat. Attach it to your [WidgetsApp.navigatorKey].
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Reject media uploads larger than this (bytes). Defaults to 25 MB.
  final int maxMediaBytes;

  /// Android resource name for the local-notification small icon, passed to
  /// `flutter_local_notifications`. Defaults to `@mipmap/ic_launcher`.
  ///
  /// The referenced resource must exist in the host app's release build. If
  /// your launcher icon uses a non-default name (e.g. `flutter_launcher_icons`
  /// generated `@mipmap/launcher_icon`), point this at it — otherwise the
  /// default may be stripped by resource shrinking and notification setup will
  /// throw `invalid_icon`. Ideally supply a white, transparent notification
  /// icon (e.g. `@drawable/ic_notification`).
  final String androidNotificationIcon;
}
