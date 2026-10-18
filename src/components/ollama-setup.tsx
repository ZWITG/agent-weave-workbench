import { useCallback, useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { CheckCircle2, Download, ExternalLink, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { db } from "@/lib/db";
import { LOCAL_USER_ID } from "@/lib/local-db/constants";
import { useAiSettings } from "@/routes/_authenticated/settings";

type State = "checking" | "missing" | "no-model" | "pulling" | "ready";

/** Desktop only: finds Ollama, downloads the model with progress, and makes it every agent's default. */
export function OllamaSetup() {
  const { data: settings } = useAiSettings();
  const qc = useQueryClient();
  const url = (settings?.ollama_url || "http://127.0.0.1:11434").replace(/\/+$/, "");
  const model = settings?.ollama_model || "qwen2.5:7b";
  const [state, setState] = useState<State>("checking");
  const [pct, setPct] = useState(0);
  const [detail, setDetail] = useState("");

  const check = useCallback(async () => {
    setState("checking");
    try {
      const j = (await (await fetch(`${url}/api/tags`)).json()) as { models?: { name: string }[] };
      const has = j.models?.some((m) => m.name === model || m.name === `${model}:latest`);
      setState(has ? "ready" : "no-model");
    } catch {
      setState("missing");
    }
  }, [url, model]);

  useEffect(() => {
    void check();
  }, [check]);

  const pull = async () => {
    setState("pulling");
    setPct(0);
    try {
      const res = await fetch(`${url}/api/pull`, { method: "POST", body: JSON.stringify({ model, stream: true }) });
      const reader = res.body!.getReader();
      const dec = new TextDecoder();
      let buf = "";
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += dec.decode(value, { stream: true });
        const lines = buf.split("\n");
        buf = lines.pop() ?? "";
        for (const l of lines) {
          if (!l.trim()) continue;
          const e = JSON.parse(l) as { status?: string; total?: number; completed?: number; error?: string };
          if (e.error) throw new Error(e.error);
          if (e.total && e.completed) setPct(Math.round((e.completed / e.total) * 100));
          if (e.status) setDetail(e.status);
        }
      }
      await db
        .from("ai_settings")
        .upsert({ user_id: LOCAL_USER_ID, default_provider: "ollama", updated_at: new Date().toISOString() });
      void qc.invalidateQueries({ queryKey: ["ai_settings"] });
      toast.success(`${model} is ready — your agents now think on this computer`);
      await check();
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Download failed");
      setState("no-model");
    }
  };

  if (state === "ready")
    return (
      <div className="mt-6 flex items-center gap-2 rounded-lg border border-border bg-card p-3 text-sm">
        <CheckCircle2 className="h-4 w-4 text-primary" /> Offline AI ready · <span className="font-mono">{model}</span>
      </div>
    );

  return (
    <div className="mt-6 rounded-lg border border-primary/40 bg-card p-4">
      <div className="font-semibold">Set up offline AI</div>
      {state === "checking" && <p className="mt-1 text-sm text-muted-foreground">Looking for Ollama on this computer…</p>}
      {state === "missing" && (
        <>
          <p className="mt-1 text-sm text-muted-foreground">
            Tensai uses Ollama to run AI on your computer for free, with no internet. Install it, open it, then check again.
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            <Button asChild>
              <a href="https://ollama.com/download" target="_blank" rel="noreferrer">
                <ExternalLink className="h-4 w-4" /> Get Ollama
              </a>
            </Button>
            <Button variant="secondary" onClick={() => void check()}>
              <RefreshCw className="h-4 w-4" /> Check again
            </Button>
          </div>
        </>
      )}
      {state === "no-model" && (
        <>
          <p className="mt-1 text-sm text-muted-foreground">
            Ollama is running. Download the <span className="font-mono">{model}</span> model once (about 4.7 GB) — after that it works offline.
          </p>
          <Button className="mt-3" onClick={() => void pull()}>
            <Download className="h-4 w-4" /> Download model
          </Button>
        </>
      )}
      {state === "pulling" && (
        <div className="mt-3 space-y-2">
          <Progress value={pct} />
          <div className="text-xs text-muted-foreground">
            {detail} {pct ? `· ${pct}%` : ""}
          </div>
        </div>
      )}
    </div>
  );
}
