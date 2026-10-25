export type RunMode = "run" | "plan";
export type RunStatus = "running" | "completed" | "failed" | "awaiting_approval";

/** Tools that only read; everything else (save_knowledge, write_file, create_helper_agent) has side effects. */
export const READ_ONLY_TOOLS = [
  "search_knowledge",
  "web_search",
  "read_page",
  "read_file",
  "list_files",
] as const;

export function filterToolsForMode<T extends Record<string, unknown>>(tools: T, mode: RunMode): T {
  if (mode !== "plan") return tools;
  const allowed = new Set<string>(READ_ONLY_TOOLS);
  return Object.fromEntries(Object.entries(tools).filter(([name]) => allowed.has(name))) as T;
}

export const planInstructions = `

PLAN MODE: do not do the work yet. Use only your read-only tools to research, then reply with a plan the owner can approve. Nothing you write is saved or run until they approve it. Use exactly these headings:

## Goal
## What I found
## Steps
(numbered; give each step an owner agent and its output)
## Files / knowledge that will be created or changed
## Risks & open questions
## How we'll check it worked`;

const TRANSITIONS: Record<RunStatus, RunStatus[]> = {
  running: ["completed", "failed", "awaiting_approval"],
  awaiting_approval: ["running", "failed"],
  completed: ["running"],
  failed: [],
};

export function canTransition(from: RunStatus, to: RunStatus) {
  return TRANSITIONS[from]?.includes(to) ?? false;
}

/** Input handed to the engine: an approved plan is followed, a pending one is revised. */
export function inputWithPlan(
  input: string,
  plan: string | null,
  mode: RunMode,
  output: string | null,
) {
  if (output)
    return `${input}\n\nPrevious work (continue and revise, do not start over):\n${output}`;
  if (!plan) return input;
  return mode === "plan"
    ? `${input}\n\nPrevious plan (revise it using the follow-ups):\n${plan}`
    : `${input}\n\nApproved plan (follow it):\n${plan}`;
}

export const statusLabel = (status: string) =>
  status === "awaiting_approval" ? "needs approval" : status;
