import 'package:chat_kit/src/config/chat_config.dart' show ChatConfig;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show immutable;

/// A participant in a chat.
///
/// The host app owns the user directory; this is the minimal projection the
/// chat package needs to render names and avatars. Build it from your own
/// directory via [ChatConfig.resolveUser]/[ChatConfig.fetchContacts], or from a
/// Firebase Auth [User] via [ChatUser.fromFirebaseUser].
@immutable
class ChatUser {
  /// Creates a chat participant.
  const ChatUser({
    required this.id,
    required this.name,
    this.photoUrl,
    this.email,
  });

  /// Builds a [ChatUser] from a Firebase Auth [User], falling back to the
  /// email or uid when no display name is set.
  factory ChatUser.fromFirebaseUser(User user) {
    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!
        : (user.email ?? user.uid);
    return ChatUser(
      id: user.uid,
      name: name,
      photoUrl: user.photoURL,
      email: user.email,
    );
  }

  /// Builds a [ChatUser] from a denormalized `participantInfo` map.
  factory ChatUser.fromMap(String id, Map<String, dynamic> map) {
    return ChatUser(
      id: id,
      name: (map['name'] as String?) ?? id,
      photoUrl: map['photoUrl'] as String?,
      email: map['email'] as String?,
    );
  }

  /// The user's unique id. Must match the Firebase Auth `uid` so that messages
  /// and security rules line up.
  final String id;

  /// The user's display name.
  final String name;

  /// URL of the user's avatar, if any.
  final String? photoUrl;

  /// The user's email address, if known.
  final String? email;

  /// The compact projection stored inside `chats/{id}.participantInfo`.
  Map<String, dynamic> toInfoMap() => {
    'name': name,
    if (photoUrl != null) 'photoUrl': photoUrl,
  };

  /// Returns a copy with the given fields replaced. The [id] is preserved.
  ChatUser copyWith({String? name, String? photoUrl, String? email}) {
    return ChatUser(
      id: id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) => other is ChatUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
