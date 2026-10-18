import { createOpenAI } from "@ai-sdk/openai";
import type { LanguageModel } from "ai";
import type { SharedV4ProviderOptions } from "@ai-sdk/provider";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";
import { resolveProviderKind, type ProviderKind } from "./ai-settings";

type Db = SupabaseClient<Database>;
export type Settings = Database["public"]["Tables"]["ai_settings"]["Row"];

export const LOVABLE_MODEL = "openai/gpt-6-astra";
const RUN_ID_HEADER = "X-Lovable-AIG-Run-ID";

export type ResolvedModel = {
  kind: ProviderKind;
  model: LanguageModel;
  providerOptions?: SharedV4ProviderOptions;
};

export async function loadSettings(db: Db, userId: string): Promise<Settings | null> {
  const { data } = await db.from("ai_settings").select("*").eq("user_id", userId).maybeSingle();
  return data;
}

function lovableModel(apiKey: string, reasoningEffort: "low" | "medium"): ResolvedModel {
  let runId: string | undefined;
  const provider = createOpenAI({
    baseURL: "https://ai.gateway.lovable.dev/v1",
    apiKey,
    headers: { "Lovable-API-Key": apiKey, "X-Lovable-AIG-SDK": "vercel-ai-sdk" },
    fetch: async (input, init) => {
      const headers = new Headers(init?.headers);
      if (runId) headers.set(RUN_ID_HEADER, runId);
      const res = await fetch(input, { ...init, headers });
      runId ??= res.headers.get(RUN_ID_HEADER)?.trim() || undefined;
      return res;
    },
  });
  return {
    kind: "lovable",
    model: provider.responses(LOVABLE_MODEL),
    providerOptions: {
      openai: {
        forceReasoning: true,
        reasoningEffort,
        reasoningSummary: "auto",
        store: false,
        include: ["reasoning.encrypted_content"],
      },
    },
  };
}

/** Picks the AI an agent should use: built-in (Lovable credits), local Ollama, or the owner's own key. */
export function resolveModel(
  settings: Settings | null,
  agentProvider: string | null | undefined,
  reasoningEffort: "low" | "medium" = "low",
): ResolvedModel {
  const kind = resolveProviderKind(agentProvider, settings?.default_provider);
  if (kind === "ollama") {
    const base = (settings?.ollama_url || "http://localhost:11434").replace(/\/+$/, "").replace(/\/v1$/, "");
    const p = createOpenAI({ baseURL: `${base}/v1`, apiKey: "ollama" });
    return { kind, model: p.chat(settings?.ollama_model || "qwen2.5:7b") };
  }
  if (kind === "custom") {
    if (!settings?.custom_api_key) throw new Error("Add your own AI key in Settings first.");
    const p = createOpenAI({ baseURL: settings.custom_base_url.replace(/\/+$/, ""), apiKey: settings.custom_api_key });
    return { kind, model: p.chat(settings.custom_model) };
  }
  const key = process.env["LOVABLE_API_KEY"];
  if (!key) throw new Error("Built-in AI isn't available here. Choose Ollama or your own key in Settings.");
  return lovableModel(key, reasoningEffort);
}
