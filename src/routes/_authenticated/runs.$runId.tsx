import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";
import { ArrowLeft, Download, FileCode } from "lucide-react";
import { db as supabase } from "@/lib/db";
import { Button } from "@/components/ui/button";
import { StatusDot } from "./dashboard";

export const Route = createFileRoute("/_authenticated/runs/$runId")({
  head: () => ({
    meta: [
      { title: "Run — Tensai" },
      { name: "description", content: "Live execution log and output." },
      { property: "og:title", content: "Run — Tensai" },
      { property: "og:description", content: "Live execution log and output." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: RunPage,
});

const kindColor: Record<string, string> = {
  start: "text-accent",
  output: "text-foreground",
  tool: "text-muted-foreground",
  error: "text-destructive",
  stage: "text-primary",
  done: "text-success",
  knowledge: "text-chart-3",
  helper: "text-chart-3",
  file: "text-chart-4",
};

function RunPage() {
  const { runId } = Route.useParams();
  const qc = useQueryClient();
  const bottom = useRef<HTMLDivElement>(null);
  const [file, setFile] = useState<string | null>(null);

  const { data: run } = useQuery({
    queryKey: ["run", runId],
    queryFn: async () => (await supabase.from("runs").select("*").eq("id", runId).single()).data,
  });
  const { data: logs = [] } = useQuery({
    queryKey: ["logs", runId],
    queryFn: async () =>
      (await supabase.from("run_logs").select("*").eq("run_id", runId).order("id")).data ?? [],
  });
  const { data: files = [] } = useQuery({
    queryKey: ["artifacts", runId],
    queryFn: async () =>
      (await supabase.from("artifacts").select("*").eq("run_id", runId).order("path")).data ?? [],
  });

  useEffect(() => {
    const ch = supabase
      .channel(`run-${runId}`)
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "run_logs", filter: `run_id=eq.${runId}` },
        () => qc.invalidateQueries({ queryKey: ["logs", runId] }),
      )
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "runs", filter: `id=eq.${runId}` },
        () => qc.invalidateQueries({ queryKey: ["run", runId] }),
      )
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "artifacts", filter: `run_id=eq.${runId}` },
        () => qc.invalidateQueries({ queryKey: ["artifacts", runId] }),
      )
      .subscribe();
    return () => {
      supabase.removeChannel(ch);
    };
  }, [runId, qc]);

  useEffect(() => {
    bottom.current?.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }, [logs.length]);

  const current = files.find(
    (f) => f.path === (file ?? files.find((x) => x.path.endsWith(".html"))?.path ?? files[0]?.path),
  );
  const isHtml = current?.path.endsWith(".html");
  const download = (path: string, content: string) => {
    const url = URL.createObjectURL(new Blob([content], { type: "text/plain" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = path.split("/").pop() ?? "file.txt";
    a.click();
    URL.revokeObjectURL(url);
  };

  if (!run) return <p className="text-muted-foreground">Loading run…</p>;

  return (
    <div>
      <Link
        to="/dashboard"
        className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" /> Control room
      </Link>
      <div className="mt-3 flex items-center gap-3">
        <StatusDot status={run.status} />
        <span className="font-mono text-xs uppercase text-muted-foreground">
          {run.status} · {run.workflow_name}
        </span>
      </div>
      <h1 className="mt-2 text-2xl font-bold">{run.input}</h1>

      <div className="mt-6 rounded-lg border border-border bg-sidebar">
        <div className="border-b border-border px-4 py-2 font-mono text-xs text-muted-foreground">
          LIVE LOG
        </div>
        <div className="max-h-[480px] space-y-2 overflow-y-auto p-4 font-mono text-sm">
          {logs.map((l) => (
            <div key={l.id} className="flex gap-3">
              <span className="shrink-0 text-xs text-muted-foreground">
                {new Date(l.created_at).toLocaleTimeString()}
              </span>
              <span className="shrink-0 text-primary">[{l.agent_name}]</span>
              <span
                className={`whitespace-pre-wrap break-words ${kindColor[l.kind] ?? ""} ${l.kind === "output" ? "line-clamp-6" : ""}`}
              >
                {l.message}
              </span>
            </div>
          ))}
          {run.status === "running" && (
            <div className="animate-pulse text-muted-foreground">▍ agents working…</div>
          )}
          <div ref={bottom} />
        </div>
      </div>

      {files.length > 0 && (
        <div className="mt-6 rounded-lg border border-border bg-card">
          <div className="flex flex-wrap items-center gap-2 border-b border-border p-3">
            <span className="font-mono text-xs text-muted-foreground">PROJECT FILES</span>
            {files.map((f) => (
              <button
                key={f.id}
                onClick={() => setFile(f.path)}
                className={`inline-flex items-center gap-1 rounded px-2 py-1 font-mono text-xs ${current?.path === f.path ? "bg-primary text-primary-foreground" : "bg-secondary"}`}
              >
                <FileCode className="h-3 w-3" /> {f.path}
              </button>
            ))}
          </div>
          {current && (
            <div className="p-3">
              <div className="mb-2 flex justify-end">
                <Button
                  size="sm"
                  variant="secondary"
                  onClick={() => download(current.path, current.content)}
                >
                  <Download className="h-4 w-4" /> Download
                </Button>
              </div>
              {isHtml ? (
                <iframe
                  title="Preview"
                  sandbox="allow-scripts"
                  srcDoc={current.content}
                  className="h-[560px] w-full rounded border border-border bg-background"
                />
              ) : (
                <pre className="max-h-[560px] overflow-auto rounded bg-sidebar p-4 font-mono text-xs">
                  {current.content}
                </pre>
              )}
            </div>
          )}
        </div>
      )}

      {run.output && (
        <div className="mt-6 rounded-lg border border-border bg-card p-5">
          <div className="font-mono text-xs text-primary">FINAL OUTPUT</div>
          <div className="mt-3 whitespace-pre-wrap text-sm leading-relaxed">{run.output}</div>
        </div>
      )}
    </div>
  );
}
