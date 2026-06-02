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
    this.onNotificationTap,
    this.navigatorKey,
    this.maxMediaBytes = 25 * 1024 * 1024,
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
}
