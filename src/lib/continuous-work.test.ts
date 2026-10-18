import { describe, expect, it } from "vitest";
import { appendFollowUps, unseenFollowUps, queuedMessage } from "./continuous-work";

describe("continuous work", () => {
  it("accepts follow-ups without discarding earlier work", () => {
    expect(appendFollowUps([{ role: "assistant", content: "Working" }], [{ id: 1, message: "Make it green" }]))
      .toEqual([{ role: "assistant", content: "Working" }, { role: "user", content: "Make it green" }]);
  });
  it("delivers each instruction once even with descending desktop IDs", () => {
    expect(unseenFollowUps([{ id: -1, message: "first" }, { id: -2, message: "second" }], new Set([-1])))
      .toEqual([{ id: -2, message: "second" }]);
  });
  it("keeps continuous chat replies as separate user messages", () => {
    const first = queuedMessage("Continue building");
    const second = queuedMessage("Add a button");
    expect(first.id).not.toBe(second.id);
    expect(second.parts).toEqual([{ type: "text", text: "Add a button" }]);
    expect(second.role).toBe("user");
  });
});