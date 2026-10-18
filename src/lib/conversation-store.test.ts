import { describe, it, expect } from "vitest";
import { conversationKey, updateConversation, conversationText } from "./conversation-store";
import type { UIMessage } from "ai";
const message = (text: string): UIMessage => ({ id: text, role: "user", parts: [{ type: "text", text }] });
describe("device conversations", () => {
  it("keeps ongoing conversations separate per agent", () => {
    const first = updateConversation({}, "a", { messages: [message("First")] });
    const next = updateConversation(first, "b", { messages: [message("Second")] });
    expect(conversationText(next["a"]?.messages ?? [])).toBe("You: First");
    expect(conversationText(next["b"]?.messages ?? [])).toBe("You: Second");
  });
  it("saves every conversation as editable knowledge without undoing edits", () => {
    const first = updateConversation({}, "a", { messages: [message("First")] });
    expect(first["a"]?.knowledge).toBe("You: First");
    const edited = updateConversation(first, "a", { knowledge: "Edited lesson" });
    const next = updateConversation(edited, "a", { messages: [message("First"), message("Second")] });
    expect(next["a"]?.knowledge).toBe("Edited lesson\n\nYou: Second");
  });
  it("keeps invited agents attached only to the selected conversation", () => {
    const first = updateConversation({}, "a", { invited: ["b"] });
    const next = updateConversation(first, "c", {});
    expect(next["a"]?.invited).toEqual(["b"]);
    expect(next["c"]?.invited).toEqual([]);
  });
  it("isolates device storage between signed-in owners", () => {
    expect(conversationKey("owner-a")).not.toBe(conversationKey("owner-b"));
  });
});