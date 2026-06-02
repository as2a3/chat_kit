import 'dart:async';

import 'package:chat_kit/src/models/presence.dart';
import 'package:chat_kit/src/services/firebase_refs.dart';
import 'package:firebase_database/firebase_database.dart';

/// Online/last-seen presence backed by the Realtime Database.
///
/// RTDB is used (rather than Firestore) because its `onDisconnect` handler lets
/// the *server* mark a user offline the moment their socket drops — something
/// Firestore can't do reliably for "went offline" detection.
class PresenceRepository {
  /// Creates a [PresenceRepository] backed by the given Firebase [refs].
  PresenceRepository({required this.refs});

  /// Typed Firebase references used to read and write presence data.
  final FirebaseRefs refs;

  StreamSubscription<DatabaseEvent>? _connSub;

  /// Begins tracking [uid]'s presence: marks them online now and registers an
  /// `onDisconnect` that flips them offline (with a `lastSeen` stamp) when the
  /// connection drops. Re-runs whenever connectivity is regained.
  Future<void> start(String uid) async {
    await stop();
    final ref = refs.presence(uid);

    _connSub = refs.connectedInfo.onValue.listen((event) async {
      final connected = event.snapshot.value == true;
      if (!connected) return;

      // Queue the offline write first so it survives an abrupt disconnect...
      await ref.onDisconnect().set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
      // ...then announce that we're online.
      await ref.set({
        'online': true,
        'lastSeen': ServerValue.timestamp,
      });
    });
  }

  /// Stops tracking and marks [uid] offline immediately (graceful sign-out).
  Future<void> stop([String? uid]) async {
    await _connSub?.cancel();
    _connSub = null;
    if (uid != null) {
      await refs.presence(uid).onDisconnect().cancel();
      await refs.presence(uid).set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
  }

  /// Live presence for a single user.
  Stream<Presence> watch(String uid) {
    return refs
        .presence(uid)
        .onValue
        .map(
          (event) => Presence.fromMap(
            event.snapshot.value as Map<dynamic, dynamic>?,
          ),
        );
  }
}
