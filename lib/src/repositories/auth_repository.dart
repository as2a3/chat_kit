import 'package:chat_kit/src/config/chat_config.dart';
import 'package:chat_kit/src/models/chat_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Bridges the host app's Firebase Auth session into the chat package.
///
/// The package does **no** sign-in itself — it assumes the host already
/// authenticated the user and simply reads [FirebaseAuth.currentUser].
class AuthRepository {
  /// Creates an [AuthRepository] from the host [config], optionally injecting a
  /// [FirebaseAuth] instance (defaults to [FirebaseAuth.instance]).
  AuthRepository({required this.config, FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  /// The chat configuration supplied by the host app.
  final ChatConfig config;
  final FirebaseAuth _auth;

  /// The currently signed-in user's uid, or throws if the host launched chat
  /// without an authenticated session.
  String get currentUid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'chat_kit: no authenticated Firebase user. Sign in with '
        'FirebaseAuth before opening the chat UI.',
      );
    }
    return user.uid;
  }

  /// Whether a Firebase user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// The current user as a [ChatUser]. Prefers richer info from
  /// [ChatConfig.resolveUser] when available, otherwise derives from the
  /// Firebase Auth profile.
  Future<ChatUser> currentUser() async {
    final user = _auth.currentUser!;
    final resolved = await config.resolveUser?.call(user.uid);
    return resolved ?? ChatUser.fromFirebaseUser(user);
  }

  /// Resolve any user for display, falling back to a placeholder so the UI
  /// always has *something* to show.
  Future<ChatUser> resolve(String uid) async {
    final resolved = await config.resolveUser?.call(uid);
    if (resolved != null) return resolved;
    final current = _auth.currentUser;
    if (current != null && current.uid == uid) {
      return ChatUser.fromFirebaseUser(current);
    }
    return ChatUser(id: uid, name: 'Unknown');
  }
}
