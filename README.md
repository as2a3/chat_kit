# chat_kit

A drop-in, **WhatsApp-style chat package for Flutter, backed by Firebase**.
Designed to be embedded in an app that has *already* signed the user in with
Firebase Auth — call it after login and it gives you a complete chat experience:
conversation list, message threads, groups, media, read receipts, typing
indicators and presence.

## Features

- **1-on-1 & group chats** — deterministic direct-chat ids prevent duplicates.
- **Media & files** — images, video, voice/audio and documents via Firebase Storage.
- **Read receipts** — sent / delivered / read ticks derived from `readBy`.
- **Typing indicators & presence** — online / last-seen via the Realtime Database (`onDisconnect`).
- **Push notifications** — FCM via a bundled Cloud Function; foreground messages shown as local notifications, taps deep-link into the chat.
- **Per-user mute** — each member can mute a chat to silence pushes (unread counts still update); a toggle lives in the chat info screen.
- **Drop-in, themeable UI** — navigate to a single screen; light & dark presets, or supply your own `ChatTheme`.
- **Backend-agnostic user directory** — the package never owns your users; it asks via callbacks.

## Architecture

A hybrid Firebase backend:

| Concern | Service | Path |
| --- | --- | --- |
| Chats & messages | Cloud Firestore | `chats/{chatId}` · `chats/{chatId}/messages/{messageId}` |
| Presence & typing | Realtime Database | `presence/{uid}` · `typing/{chatId}/{uid}` |
| Media | Cloud Storage | `chat_media/{chatId}/{messageId}/{file}` |

Layered internally: **models → repositories → controllers → UI**. Repositories
expose `Stream`s consumed by `ChangeNotifier` controllers and `StreamBuilder`s —
no heavy state-management dependency.

## Getting started

### 1. Firebase setup

Add Firebase to your host app and enable:
- **Authentication** (any provider your app uses)
- **Cloud Firestore**
- **Realtime Database**
- **Cloud Storage**

The simplest path is [`flutterfire configure`](https://firebase.google.com/docs/flutter/setup).

### 2. Initialize & sign in (host app's job)

```dart
await Firebase.initializeApp();
await FirebaseAuth.instance.signInWith...(); // your existing login
```

### 3. Configure the package and open chat

```dart
import 'package:chat_kit/chat_kit.dart';

ChatKit.configure(ChatConfig(
  theme: ChatTheme.whatsapp(),            // .light() / .dark() / .amoled(), .copyWith(...), or your own
  // Wire these to YOUR user directory:
  resolveUser:  (uid) => myDirectory.user(uid),     // name/avatar for a uid
  fetchContacts: ()   => myDirectory.contacts(),     // who you can start chats with
));

await ChatKit.instance.startPresence();          // call once after login
await ChatKit.instance.initPushNotifications();  // register for FCM (optional)

Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => const ConversationsScreen(),       // the only screen you need
));
```

On sign-out:

```dart
await ChatKit.dispose(); // marks offline, removes push token, tears down
```

> The current user's identity comes from `FirebaseAuth.instance.currentUser`.
> `ChatUser.id` **must** equal the Firebase `uid` so messages and security rules
> line up.

## Security rules

These rules scope every read/write to chat participants. Adjust to your needs.

### Firestore (`firestore.rules`)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }
    function isParticipant(chatId) {
      return signedIn() &&
        request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    }

    // Each user owns their FCM token document.
    match /fcm_tokens/{uid} {
      allow read, write: if signedIn() && request.auth.uid == uid;
    }

    match /chats/{chatId} {
      allow read: if signedIn() && request.auth.uid in resource.data.participants;
      // Allow create when the creator includes themselves as a participant.
      allow create: if signedIn() && request.auth.uid in request.resource.data.participants;
      allow update: if signedIn() && request.auth.uid in resource.data.participants;

      match /messages/{messageId} {
        allow read: if isParticipant(chatId);
        allow create: if isParticipant(chatId)
                       && request.resource.data.senderId == request.auth.uid;
        // Allow updating readBy (receipts) by any participant; restrict deletes
        // to the original sender.
        allow update: if isParticipant(chatId);
        allow delete: if isParticipant(chatId)
                       && resource.data.senderId == request.auth.uid;
      }
    }
  }
}
```

### Realtime Database (`database.rules.json`)

```json
{
  "rules": {
    "presence": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "typing": {
      "$chatId": {
        ".read": "auth != null",
        "$uid": {
          ".write": "auth != null && auth.uid == $uid"
        }
      }
    }
  }
}
```

### Storage (`storage.rules`)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /chat_media/{chatId}/{messageId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                    && request.resource.size < 25 * 1024 * 1024;
    }
  }
}
```

> The Storage rule keeps it simple (any signed-in user). To restrict to chat
> participants, mirror the Firestore `participants` check via a Cloud Function
> or by storing per-chat membership claims.

## Push notifications

Push has two halves: the **client** (this package) registers the device and
shows/routes notifications, and a **Cloud Function** (bundled in `functions/`)
sends the push whenever a message is written.

### 1. Deploy the Cloud Function

```bash
cd functions
npm install
npm run deploy        # firebase deploy --only functions
```

It triggers on `chats/{chatId}/messages/{messageId}` creation, reads each
recipient's tokens from `fcm_tokens/{uid}`, sends an FCM multicast, and prunes
tokens FCM reports as invalid. The notification carries a `data.chatId` so taps
can deep-link.

### 2. Enable it in the client

```dart
ChatKit.configure(ChatConfig(
  enablePushNotifications: true,            // default
  // EITHER let the package open the tapped chat for you…
  navigatorKey: myNavigatorKey,             // also passed to MaterialApp(navigatorKey: …)
  // …OR handle routing yourself:
  onNotificationTap: (chatId) => myRouter.openChat(chatId),
));

await ChatKit.instance.initPushNotifications(); // after login
```

Behavior:
- **Foreground** → shown via `flutter_local_notifications` (suppressed for the
  chat you're currently viewing).
- **Background / terminated** → drawn by the OS from the `notification` payload;
  tapping deep-links to the chat (via `navigatorKey` or `onNotificationTap`).
- **Muted chats** → the Cloud Function skips any recipient listed in the chat's
  `mutedBy` array (toggled from the chat info screen), so they get no push while
  unread counts still update.

### 3. Platform setup

- **Android** — no extra code; the package creates a high-importance channel.
  On Android 13+ the runtime POST_NOTIFICATIONS permission is requested by
  `initPushNotifications()`.
- **iOS** — enable *Push Notifications* and *Background Modes → Remote
  notifications* capabilities, and upload your **APNs key** to the Firebase
  console. Tokens only resolve on a physical device.

### Token schema

```
fcm_tokens/{uid} {
  tokens:    [ "<device-token>", ... ],   // arrayUnion on register, arrayRemove on logout/prune
  platform:  "android" | "iOS" | ...,
  updatedAt: <server timestamp>
}
```

## Suggested Firestore index

The conversations query orders a user's chats by recency, which needs a
composite index:

```
Collection: chats
Fields: participants (Array contains) + updatedAt (Descending)
```

Firestore prints a one-click creation link the first time the query runs.

## Example

See [`example/`](example/) for a minimal host app. Run `flutter create .` inside
it to generate platform projects, add your Firebase config, then `flutter run`.

## Not included (v1)

Extension points for later: message reactions/edits/deletes, end-to-end
encryption, and voice/video calls.
