import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { isDesktop, PROVIDER_LABELS, type ProviderKind } from "@/lib/ai-settings";

export const Route = createFileRoute("/_authenticated/settings")({
  head: () => ({
    meta: [
      { title: "AI settings — Hive" },
      { name: "description", content: "Choose which AI your agents think with." },
      { property: "og:title", content: "AI settings — Hive" },
      { property: "og:description", content: "Choose which AI your agents think with." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: SettingsPage,
});

const defaults = {
  default_provider: "lovable" as string,
  ollama_url: "http://localhost:11434",
  ollama_model: "qwen2.5:7b",
  custom_base_url: "https://api.openai.com/v1",
  custom_api_key: "",
  custom_model: "gpt-4o-mini",
};

export function useAiSettings() {
  return useQuery({
    queryKey: ["ai_settings"],
    queryFn: async () => {
      const { data, error } = await supabase.from("ai_settings").select("*").maybeSingle();
      if (error) throw error;
      return data;
    },
  });
}

const PRESETS = [
  { label: "OpenAI", url: "https://api.openai.com/v1", model: "gpt-4o-mini" },
  {
    label: "Groq (free tier)",
    url: "https://api.groq.com/openai/v1",
    model: "llama-3.3-70b-versatile",
  },
  {
    label: "Gemini (free tier)",
    url: "https://generativelanguage.googleapis.com/v1beta/openai",
    model: "gemini-2.0-flash",
  },
  {
    label: "OpenRouter",
    url: "https://openrouter.ai/api/v1",
    model: "meta-llama/llama-3.3-70b-instruct",
  },
];

function SettingsPage() {
  const { data } = useAiSettings();
  const qc = useQueryClient();
  const [form, setForm] = useState(defaults);
  const [saving, setSaving] = useState(false);
  const [desktop, setDesktop] = useState(false);

  useEffect(() => setDesktop(isDesktop()), []);
  useEffect(() => {
    if (data) setForm({ ...defaults, ...data });
  }, [data]);

  const save = async () => {
    setSaving(true);
    const { data: u } = await supabase.auth.getUser();
    const { error } = await supabase
      .from("ai_settings")
      .upsert({ ...form, user_id: u.user!.id, updated_at: new Date().toISOString() });
    setSaving(false);
    if (error) return void toast.error(error.message);
    toast.success("AI settings saved");
    qc.invalidateQueries({ queryKey: ["ai_settings"] });
  };

  const testOllama = async () => {
    try {
      const res = await fetch(`${form.ollama_url.replace(/\/+$/, "")}/api/tags`);
      const j = (await res.json()) as { models?: { name: string }[] };
      toast.success(
        `Ollama is running. Models: ${j.models?.map((m) => m.name).join(", ") || "none yet"}`,
      );
    } catch {
      toast.error("Can't reach Ollama. Is it installed and running?");
    }
  };

  const set = (k: keyof typeof defaults) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm({ ...form, [k]: e.target.value });

  return (
    <div className="max-w-2xl">
      <div className="font-mono text-xs text-primary">BRAINS</div>
      <h1 className="text-3xl font-bold">AI settings</h1>
      <p className="mt-2 text-sm text-muted-foreground">
        Choose which AI your agents think with. Only the built-in AI uses Lovable credits. Each
        agent can also pick its own on the Agents page.
      </p>

      <section className="mt-8 rounded-lg border border-border bg-card p-5">
        <Label>Default for all agents</Label>
        <div className="mt-3 grid gap-2">
          {(["lovable", "ollama", "custom"] as ProviderKind[]).map((k) => (
            <label key={k} className="flex items-center gap-3 text-sm">
              <input
                type="radio"
                name="default_provider"
                checked={form.default_provider === k}
                onChange={() => setForm({ ...form, default_provider: k })}
              />
              {PROVIDER_LABELS[k]}
              {k === "lovable" && desktop && (
                <span className="text-xs text-muted-foreground">
                  (not available in the desktop app)
                </span>
              )}
            </label>
          ))}
        </div>
      </section>

      <section className="mt-6 rounded-lg border border-border bg-card p-5">
        <h2 className="font-semibold">Ollama — free, on your computer</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Install Ollama from ollama.com, then run{" "}
          <code className="font-mono">ollama pull qwen2.5:7b</code>. Works in the desktop app only
          (the website can't see your computer).
        </p>
        <div className="mt-4 grid gap-3">
          <div>
            <Label htmlFor="ou">Address</Label>
            <Input id="ou" value={form.ollama_url} onChange={set("ollama_url")} />
          </div>
          <div>
            <Label htmlFor="om">Model</Label>
            <Input id="om" value={form.ollama_model} onChange={set("ollama_model")} />
          </div>
          <Button variant="secondary" className="w-fit" onClick={testOllama}>
            Test connection
          </Button>
        </div>
      </section>

      <section className="mt-6 rounded-lg border border-border bg-card p-5">
        <h2 className="font-semibold">My own API key</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          You pay that company directly. Groq and Gemini have free tiers.
        </p>
        <div className="mt-3 flex flex-wrap gap-2">
          {PRESETS.map((p) => (
            <Button
              key={p.label}
              size="sm"
              variant="outline"
              onClick={() => setForm({ ...form, custom_base_url: p.url, custom_model: p.model })}
            >
              {p.label}
            </Button>
          ))}
        </div>
        <div className="mt-4 grid gap-3">
          <div>
            <Label htmlFor="cu">Service address</Label>
            <Input id="cu" value={form.custom_base_url} onChange={set("custom_base_url")} />
          </div>
          <div>
            <Label htmlFor="ck">API key</Label>
            <Input
              id="ck"
              type="password"
              value={form.custom_api_key}
              onChange={set("custom_api_key")}
              placeholder="Paste your key"
            />
          </div>
          <div>
            <Label htmlFor="cm">Model</Label>
            <Input id="cm" value={form.custom_model} onChange={set("custom_model")} />
          </div>
        </div>
      </section>

      <Button className="mt-6" onClick={save} disabled={saving}>
        {saving ? "Saving…" : "Save settings"}
      </Button>
    </div>
  );
}
