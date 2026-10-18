export const SKILLS = [
  { id: "web_search", label: "Web search", desc: "Search and read pages online" },
  { id: "write", label: "Summarize & write", desc: "Reasoning, writing, summarizing" },
  { id: "structured", label: "Structured output", desc: "Emit JSON tables for the next agent" },
  { id: "build", label: "Build projects", desc: "Write real files: games, web apps, code, songs" },
  { id: "create_helper", label: "Create helper AI", desc: "Spawn new specialist agents to learn a task" },
] as const;

export const COLORS = ["amber", "teal", "violet", "rose", "lime", "sky"] as const;

export const colorClass: Record<string, string> = {
  amber: "bg-chart-1",
  teal: "bg-chart-2",
  violet: "bg-chart-3",
  lime: "bg-chart-4",
  rose: "bg-chart-5",
  sky: "bg-accent",
};

export type Stage = { agent_ids: string[] };
