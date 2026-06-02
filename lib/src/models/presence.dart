/// Online/last-seen state for a user, stored in the Realtime Database under
/// `presence/{uid}` and kept fresh with an `onDisconnect` handler.
class Presence {
  /// Creates a presence state.
  const Presence({required this.online, this.lastSeen});

  /// Parses a raw RTDB snapshot value. `lastSeen` is stored as epoch millis
  /// (written with `ServerValue.timestamp`).
  factory Presence.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return offline;
    final ts = map['lastSeen'];
    return Presence(
      online: map['online'] == true,
      lastSeen: ts is int ? DateTime.fromMillisecondsSinceEpoch(ts) : null,
    );
  }

  /// Whether the user is currently online.
  final bool online;

  /// When the user was last seen online, if known.
  final DateTime? lastSeen;

  /// A shared offline presence with no last-seen time.
  static const Presence offline = Presence(online: false);
}
