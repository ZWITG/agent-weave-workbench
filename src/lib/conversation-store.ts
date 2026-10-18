import type { UIMessage } from "ai";
import { useEffect, useState } from "react";

export type DeviceConversation = {
  agentId: string;
  invited: string[];
  messages: UIMessage[];
  pending?: UIMessage[];
  knowledge: string;
  updatedAt: string;
};
export const conversationKey = (userId: string) => `hive:conversations:${userId}`;
export function conversationText(messages: UIMessage[]) {
  return messages
    .map(
      (m) =>
        `${m.role === "user" ? "You" : "Agent"}: ${m.parts
          .filter((p) => p.type === "text")
          .map((p) => p.text)
          .join("\n")}`,
    )
    .filter((s) => !s.endsWith(": "))
    .join("\n\n");
}
export function updateConversation(
  records: Record<string, DeviceConversation>,
  agentId: string,
  changes: Partial<DeviceConversation>,
) {
  const previous = records[agentId] ?? {
    agentId,
    invited: [],
    messages: [],
    knowledge: "",
    updatedAt: "",
  };
  const next = { ...previous, ...changes, updatedAt: new Date().toISOString() };
  if (changes.messages) {
    const oldTranscript = conversationText(previous.messages);
    const newTranscript = conversationText(changes.messages);
    // Keep user-edited knowledge intact and append only new transcript content.
    next.knowledge =
      previous.knowledge === oldTranscript
        ? newTranscript
        : previous.knowledge +
          (newTranscript.startsWith(oldTranscript)
            ? newTranscript.slice(oldTranscript.length)
            : `\n\n${newTranscript}`);
  }
  return { ...records, [agentId]: next };
}

export function useDeviceConversations(userId: string) {
  const [records, setRecords] = useState<Record<string, DeviceConversation>>({});
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    const load = () => {
      try {
        const value = JSON.parse(localStorage.getItem(conversationKey(userId)) ?? "{}");
        setRecords(value && typeof value === "object" && !Array.isArray(value) ? value : {});
      } catch {
        setError("Could not read conversations saved on this device.");
      }
      setReady(true);
    };
    load();
    window.addEventListener("hive:conversations", load);
    window.addEventListener("storage", load);
    return () => {
      window.removeEventListener("hive:conversations", load);
      window.removeEventListener("storage", load);
    };
  }, [userId]);
  const update = (agentId: string, changes: Partial<DeviceConversation>) => {
    try {
      const current = JSON.parse(localStorage.getItem(conversationKey(userId)) ?? "{}");
      localStorage.setItem(
        conversationKey(userId),
        JSON.stringify(updateConversation(current, agentId, changes)),
      );
      window.dispatchEvent(new Event("hive:conversations"));
    } catch {
      setError("Conversation could not be saved. Device storage may be full or disabled.");
    }
  };
  const remove = (agentId: string) => {
    try {
      const current = JSON.parse(localStorage.getItem(conversationKey(userId)) ?? "{}");
      delete current[agentId];
      localStorage.setItem(conversationKey(userId), JSON.stringify(current));
      window.dispatchEvent(new Event("hive:conversations"));
    } catch {
      setError("Could not remove this conversation from your device.");
    }
  };
  return { records, ready, error, update, remove };
}
