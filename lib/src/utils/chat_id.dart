/// Helpers for deterministic chat document ids.
class ChatId {
  const ChatId._();

  /// Deterministic id for the 1-on-1 chat between [a] and [b]. The two uids are
  /// sorted and joined so the *same* pair always resolves to the *same* id,
  /// regardless of who initiates — preventing duplicate direct chats.
  static String direct(String a, String b) {
    final sorted = [a, b]..sort();
    return 'direct_${sorted[0]}_${sorted[1]}';
  }

  /// Whether [id] was produced by [direct].
  static bool isDirect(String id) => id.startsWith('direct_');
}
