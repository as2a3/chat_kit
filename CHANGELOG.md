## 0.0.7

* **Theming:** added two presets — `ChatTheme.light()` (neutral light with a
  blue accent) and `ChatTheme.amoled()` (pure black for OLED) — alongside the
  existing `whatsapp()` and `dark()`.
* `ChatTheme` now has `copyWith(...)` for deriving variants, a static
  `lerp(a, b, t)` for animating theme switches, and value equality
  (`==`/`hashCode`). Value equality makes `ChatThemeProvider` only notify on a
  real change. No breaking changes.
* `ConversationsScreen` gained a `showAppBar` flag (default `true`) for
  embedding the screen beneath a host-provided header without a duplicate bar.
  Its Scaffold background now follows `ChatTheme.background` instead of being
  hard-coded white.

## 0.0.6

* **Renamed the package** `whats_up_chat` → `chat_kit`. The facade class
  `WhatsUpChat` is now `ChatKit`, the entry library is
  `package:chat_kit/chat_kit.dart`, and the Cloud Functions package is
  `chat-kit-functions`. Update your imports and `ChatKit.configure(...)` calls.

## 0.0.5

* Adopted `very_good_analysis` and made the whole package lint-clean: doc
  comments on all public members, 80-column formatting, explicit type
  arguments, and `unawaited(...)` on fire-and-forget futures. No API or
  behavior changes.

## 0.0.4

* Conversation list long-press actions: **Mark as read** (clears the unread
  badge), **Mute/Unmute**, and **Delete chat** (per-user hide via `clearedBy`;
  reappears when a new message arrives). New `ChatRepository.deleteChatForUser`
  and `markConversationRead`; `watchConversations` filters out cleared chats.

## 0.0.3

* Per-user mute: members can mute a chat (`ChatRepository.setMuted`,
  `Conversation.isMutedFor`, toggle in the chat info screen, muted icon in the
  conversation list). The push Cloud Function skips recipients in `mutedBy`;
  unread counts are unaffected.

## 0.0.2

* Push notifications via FCM: `PushRepository` registers/refreshes device tokens
  (`fcm_tokens/{uid}`), shows foreground messages with `flutter_local_notifications`
  (suppressing the active chat), and routes taps to the chat via `navigatorKey`
  or `ChatConfig.onNotificationTap`.
* `ChatKit.initPushNotifications()` / `stopPushNotifications()`; `dispose()`
  now also removes the device token.
* Bundled deployable Cloud Function (`functions/`, TypeScript) that sends the
  push on message creation and prunes invalid tokens.

## 0.0.1

Initial release.

* 1-on-1 and group chats backed by Cloud Firestore.
* Media & file messages (image, video, audio, document) via Cloud Storage.
* Read receipts (sent / delivered / read) derived from per-message `readBy`.
* Typing indicators and online/last-seen presence via the Realtime Database.
* Drop-in, themeable WhatsApp-style UI (`ConversationsScreen` + thread, new
  chat, group create, chat info).
* `ChatKit` facade that reads the host's Firebase Auth session; backend-
  agnostic user directory via `ChatConfig.resolveUser` / `fetchContacts`.
