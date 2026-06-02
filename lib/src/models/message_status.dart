/// Delivery state of a message from the perspective of the *sender*.
///
/// In a 1-on-1 chat this maps directly to the recipient's progress. In a group
/// chat the status reflects the *least-advanced* recipient (e.g. [delivered]
/// until everyone has read it, at which point it becomes [read]).
enum MessageStatus {
  /// Written to Firestore but no recipient has loaded it yet.
  sent,

  /// At least one recipient's client has the message but hasn't opened the
  /// chat.
  delivered,

  /// All recipients have read the message.
  read,
}
