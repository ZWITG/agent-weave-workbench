import { describe, expect, it } from "vitest";
import {
  READ_ONLY_TOOLS,
  canTransition,
  filterToolsForMode,
  inputWithPlan,
  modeForStatus,
  planInstructions,
} from "./plan-mode";

const allTools = {
  save_knowledge: 1,
  search_knowledge: 1,
  web_search: 1,
  read_page: 1,
  write_file: 1,
  read_file: 1,
  list_files: 1,
  create_helper_agent: 1,
};

describe("filterToolsForMode", () => {
  it("keeps every tool in run mode", () => {
    expect(Object.keys(filterToolsForMode(allTools, "run"))).toHaveLength(8);
  });

  it("drops every tool with side effects in plan mode", () => {
    const names = Object.keys(filterToolsForMode(allTools, "plan"));
    expect(names.sort()).toEqual([...READ_ONLY_TOOLS].sort());
    expect(names).not.toContain("write_file");
    expect(names).not.toContain("save_knowledge");
    expect(names).not.toContain("create_helper_agent");
  });
});

describe("canTransition", () => {
  it("lets a plan be approved, revised or rejected", () => {
    expect(canTransition("planning", "awaiting_approval")).toBe(true);
    expect(canTransition("awaiting_approval", "running")).toBe(true);
    expect(canTransition("awaiting_approval", "planning")).toBe(true);
    expect(canTransition("awaiting_approval", "failed")).toBe(true);
  });

  it("never completes a run straight from awaiting_approval", () => {
    expect(canTransition("awaiting_approval", "completed")).toBe(false);
    expect(canTransition("running", "awaiting_approval")).toBe(false);
    expect(canTransition("failed", "running")).toBe(false);
  });
});

describe("modeForStatus", () => {
  it("treats only a planning run as plan mode", () => {
    expect(modeForStatus("planning")).toBe("plan");
    for (const status of ["running", "awaiting_approval", "completed", "failed"])
      expect(modeForStatus(status)).toBe("run");
  });
});

describe("inputWithPlan", () => {
  it("follows an approved plan", () => {
    expect(inputWithPlan("Build a game", "1. do it", "run", null)).toContain(
      "Approved plan (follow it):\n1. do it",
    );
  });

  it("revises a pending plan", () => {
    expect(inputWithPlan("Build a game", "1. do it", "plan", null)).toContain("revise");
  });

  it("prefers earlier output so existing continuations are unchanged", () => {
    expect(inputWithPlan("x", "p", "run", "out")).toContain("Previous work");
  });

  it("returns the bare input when there is no plan", () => {
    expect(inputWithPlan("x", null, "run", null)).toBe("x");
  });
});

describe("planInstructions", () => {
  it("lists the shared headings", () => {
    for (const h of ["## Goal", "## Steps", "## Risks & open questions"]) {
      expect(planInstructions).toContain(h);
    }
  });
});
