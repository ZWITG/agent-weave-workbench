import type { ModelMessage, UIMessage } from "ai";

export type FollowUp = { id: number; message: string };

/** IDs may be negative on desktop, so compare identity rather than numeric cursors. */
export function unseenFollowUps(rows: FollowUp[], seen: Set<number>) {
  return rows.filter((row) => !seen.has(row.id));
}

export function appendFollowUps(messages: ModelMessage[], rows: FollowUp[]): ModelMessage[] {
  return [
    ...messages,
    ...rows.map((row): ModelMessage => ({ role: "user", content: row.message })),
  ];
}

export function queuedMessage(text: string): UIMessage {
  return { id: crypto.randomUUID(), role: "user", parts: [{ type: "text", text }] };
}
