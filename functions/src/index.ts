/**
 * chat_kit — push notifications.
 *
 * Firestore trigger: when a message is created under
 * `chats/{chatId}/messages/{messageId}`, look up every other participant's FCM
 * tokens (from `fcm_tokens/{uid}.tokens`) and send a push. Tokens that the FCM
 * backend reports as invalid are pruned so the list stays healthy.
 *
 * Deploy:  cd functions && npm install && npm run deploy
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

initializeApp();
const db = getFirestore();

/** Mirrors ChatMessage.preview in the Dart client. */
function preview(type: string, text: string, fileName?: string): string {
  switch (type) {
    case "image":
      return "📷 Photo";
    case "video":
      return "🎥 Video";
    case "audio":
      return "🎤 Voice message";
    case "file":
      return `📎 ${fileName ?? "File"}`;
    default:
      return text || "New message";
  }
}

interface OwnedToken {
  uid: string;
  token: string;
}

export const onChatMessageCreated = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const message = snap.data();
    const chatId = event.params.chatId as string;
    const senderId = message.senderId as string;

    const chatSnap = await db.doc(`chats/${chatId}`).get();
    const chat = chatSnap.data();
    if (!chat) return;

    const participants: string[] = chat.participants ?? [];
    const mutedBy: string[] = chat.mutedBy ?? [];
    const recipients = participants.filter(
      (uid) => uid !== senderId && !mutedBy.includes(uid)
    );
    if (recipients.length === 0) return;

    const isGroup = chat.type === "group";
    const senderName: string =
      chat.participantInfo?.[senderId]?.name ?? "New message";
    const body = preview(
      message.type ?? "text",
      message.text ?? "",
      message.fileName
    );

    const title = isGroup ? (chat.name ?? "Group") : senderName;
    const displayBody = isGroup ? `${senderName}: ${body}` : body;

    // Gather every recipient device token, remembering which uid owns each so
    // we can prune the right document on failure.
    const owned: OwnedToken[] = [];
    const tokenDocs = await db.getAll(
      ...recipients.map((uid) => db.doc(`fcm_tokens/${uid}`))
    );
    tokenDocs.forEach((doc, i) => {
      const tokens: string[] = doc.data()?.tokens ?? [];
      for (const token of tokens) {
        owned.push({ uid: recipients[i], token });
      }
    });
    if (owned.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens: owned.map((o) => o.token),
      notification: { title, body: displayBody },
      data: {
        chatId,
        senderId,
        type: String(message.type ?? "text"),
      },
      android: { priority: "high" },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    });

    // Prune tokens FCM rejected as no-longer-valid.
    const stale: OwnedToken[] = [];
    response.responses.forEach((r, i) => {
      const code = r.error?.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-argument"
      ) {
        stale.push(owned[i]);
      }
    });

    if (stale.length > 0) {
      const byUser = new Map<string, string[]>();
      for (const { uid, token } of stale) {
        byUser.set(uid, [...(byUser.get(uid) ?? []), token]);
      }
      await Promise.all(
        [...byUser.entries()].map(([uid, tokens]) =>
          db.doc(`fcm_tokens/${uid}`).set(
            { tokens: FieldValue.arrayRemove(...tokens) },
            { merge: true }
          )
        )
      );
    }

    logger.info(
      `chat ${chatId}: sent ${response.successCount}/${owned.length}, ` +
        `pruned ${stale.length} stale token(s)`
    );
  }
);
