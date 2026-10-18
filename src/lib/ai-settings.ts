export type ProviderKind = "lovable" | "ollama" | "custom";
export type AgentProvider = "default" | ProviderKind;

export const PROVIDER_LABELS: Record<AgentProvider, string> = {
  default: "Use default",
  lovable: "Built-in AI (uses credits)",
  ollama: "Ollama on my computer (free)",
  custom: "My own API key",
};

/** An agent's own choice wins; "default" falls back to the owner's default; unset means built-in. */
export function resolveProviderKind(
  agentProvider: string | null | undefined,
  defaultProvider: string | null | undefined,
): ProviderKind {
  const pick = agentProvider && agentProvider !== "default" ? agentProvider : defaultProvider;
  return pick === "ollama" || pick === "custom" ? pick : "lovable";
}

/** True when running inside the Hive desktop app. */
export function isDesktop() {
  return typeof navigator !== "undefined" && /HiveDesktop/.test(navigator.userAgent);
}
