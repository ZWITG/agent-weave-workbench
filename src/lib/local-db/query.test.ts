import { describe, expect, it } from "vitest";
import { matches, shape, type Query } from "./query";

const q = (p: Partial<Query>): Query => ({
  table: "t",
  op: "select",
  filters: [],
  order: [],
  ...p,
});

describe("local storage queries", () => {
  it("knowledge search matches topic or content, case-insensitively", () => {
    const row = { topic: "Snake game", content: "use canvas" };
    expect(matches(row, [{ type: "or", expr: "topic.ilike.%SNAKE%,content.ilike.%snake%" }])).toBe(
      true,
    );
    expect(
      matches(row, [{ type: "or", expr: "topic.ilike.%tetris%,content.ilike.%tetris%" }]),
    ).toBe(false);
  });
  it("orders newest first and limits", () => {
    const rows = [{ created_at: "1" }, { created_at: "3" }, { created_at: "2" }];
    const r = shape(rows, q({ order: [{ col: "created_at", asc: false }], limit: 2 }));
    expect(r.data).toEqual([{ created_at: "3" }, { created_at: "2" }]);
  });
  it("maybeSingle returns null when nothing matches; single errors", () => {
    expect(shape([], q({ single: "maybe" })).data).toBeNull();
    expect(shape([], q({ single: "single" })).error).not.toBeNull();
  });
});
