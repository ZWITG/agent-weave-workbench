import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";
import { ArrowLeft, Download, FileCode } from "lucide-react";
import { db as supabase } from "@/lib/db";
import { Button } from "@/components/ui/button";
import { StatusDot } from "./dashboard";
import { statusLabel } from "@/lib/plan-mode";
import { Textarea } from "@/components/ui/textarea";
import { useServerFn } from "@tanstack/react-start";
import { sendRunReply, executeRunFn, approvePlan, rejectPlan } from "@/lib/engine.functions";
import {
  PromptInput,
  PromptInputTextarea,
  PromptInputFooter,
  PromptInputSubmit,
} from "@/components/ai-elements/prompt-input";
import { Message, MessageContent, MessageResponse } from "@/components/ai-elements/message";
import { ArrowUp } from "lucide-react";

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
  user_message: "text-foreground",
  steering: "text-accent",
  plan: "text-chart-4",
};

function RunPage() {
  const { runId } = Route.useParams();
  const qc = useQueryClient();
  const bottom = useRef<HTMLDivElement>(null);
  const [file, setFile] = useState<string | null>(null);
  const [reply, setReply] = useState("");
  const [sending, setSending] = useState(false);
  const [replyError, setReplyError] = useState<string | null>(null);
  const replyInput = useRef<HTMLTextAreaElement>(null);
  const sendReply = useServerFn(sendRunReply);
  const execute = useServerFn(executeRunFn);
  const approve = useServerFn(approvePlan);
  const reject = useServerFn(rejectPlan);
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState("");
  const [planBusy, setPlanBusy] = useState(false);
  const [planError, setPlanError] = useState<string | null>(null);

  const { data: run } = useQuery({
    queryKey: ["run", runId],
    queryFn: async () => (await supabase.from("runs").select("*").eq("id", runId).single()).data,
    refetchInterval: 2000,
  });
  const { data: logs = [] } = useQuery({
    queryKey: ["logs", runId],
    queryFn: async () =>
      (
        await supabase
          .from("run_logs")
          .select("*")
          .eq("run_id", runId)
          .order("created_at")
          .order("id")
      ).data ?? [],
    refetchInterval: 2000,
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
  useEffect(() => {
    replyInput.current?.focus();
  }, [run?.id]);

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

  const plan = [...logs].reverse().find((l) => l.kind === "plan")?.message ?? null;
  const decidePlan = async (action: "approve" | "reject") => {
    setPlanBusy(true);
    setPlanError(null);
    try {
      if (action === "reject") {
        await reject({ data: { runId } });
      } else {
        const edited = editing && draft.trim() && draft.trim() !== plan ? draft : undefined;
        await approve({ data: { runId, plan: edited } });
        setEditing(false);
        void execute({ data: { runId } }).catch((error: unknown) =>
          setPlanError(error instanceof Error ? error.message : "Could not start run"),
        );
      }
      await qc.invalidateQueries({ queryKey: ["logs", runId] });
      await qc.invalidateQueries({ queryKey: ["run", runId] });
    } catch (error) {
      setPlanError(error instanceof Error ? error.message : "Could not update plan");
    } finally {
      setPlanBusy(false);
    }
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
          {statusLabel(run.status)} · {run.workflow_name}
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
              {l.kind === "user_message" ? (
                <Message from="user">
                  <MessageContent className="group-[.is-user]:bg-primary group-[.is-user]:text-primary-foreground">
                    <MessageResponse>{l.message}</MessageResponse>
                  </MessageContent>
                </Message>
              ) : (
                <span
                  className={`whitespace-pre-wrap break-words ${kindColor[l.kind] ?? ""} ${l.kind === "output" || l.kind === "plan" ? "line-clamp-6" : ""}`}
                >
                  {l.message}
                </span>
              )}
            </div>
          ))}
          {(run.status === "running" || run.status === "planning") && (
            <div className="animate-pulse text-muted-foreground">▍ agents working…</div>
          )}
          <div ref={bottom} />
        </div>
      </div>

      {run.status === "awaiting_approval" && plan && (
        <div className="mt-4 rounded-lg border border-chart-4/60 bg-card p-5">
          <div className="font-mono text-xs text-chart-4">PLAN · WAITING FOR YOUR APPROVAL</div>
          {editing ? (
            <Textarea
              aria-label="Edit plan"
              rows={14}
              className="mt-3 font-mono text-sm"
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
            />
          ) : (
            <MessageResponse className="mt-3 text-sm leading-relaxed">{plan}</MessageResponse>
          )}
          {planError && (
            <p role="alert" className="mt-3 text-sm text-destructive">
              {planError}
            </p>
          )}
          <div className="mt-4 flex flex-wrap gap-2">
            <Button onClick={() => void decidePlan("approve")} disabled={planBusy}>
              Approve &amp; run
            </Button>
            {editing ? (
              <Button variant="secondary" onClick={() => setEditing(false)} disabled={planBusy}>
                Cancel edit
              </Button>
            ) : (
              <Button
                variant="secondary"
                onClick={() => {
                  setDraft(plan ?? "");
                  setEditing(true);
                }}
                disabled={planBusy}
              >
                Edit
              </Button>
            )}
            <Button variant="ghost" onClick={() => void decidePlan("reject")} disabled={planBusy}>
              Reject
            </Button>
          </div>
          <p className="mt-3 text-xs text-muted-foreground">
            Or reply below to ask for changes — the agents will revise the plan.
          </p>
        </div>
      )}

      <div className="mt-4">
        {replyError && (
          <p role="alert" className="mb-2 text-sm text-destructive">
            {replyError}
          </p>
        )}
        <PromptInput
          onSubmit={async ({ text }) => {
            if (!text.trim() || sending) return;
            setSending(true);
            setReplyError(null);
            try {
              const result = await sendReply({ data: { runId, message: text } });
              setReply("");
              await qc.invalidateQueries({ queryKey: ["logs", runId] });
              await qc.invalidateQueries({ queryKey: ["run", runId] });
              if (result.resume)
                void execute({ data: { runId } }).catch((error: unknown) =>
                  setReplyError(error instanceof Error ? error.message : "Could not continue run"),
                );
            } catch (error) {
              setReplyError(error instanceof Error ? error.message : "Could not send reply");
            } finally {
              setSending(false);
              replyInput.current?.focus();
            }
          }}
        >
          <PromptInputTextarea
            ref={replyInput}
            aria-label="Reply to agents"
            value={reply}
            onChange={(event) => setReply(event.target.value)}
            placeholder={
              run.status === "running"
                ? "Send instructions while agents work…"
                : run.status === "awaiting_approval"
                  ? "Ask for changes to the plan…"
                  : "Continue working on this…"
            }
            disabled={run.status === "failed"}
          />
          <PromptInputFooter className="justify-between">
            <span className="text-xs text-muted-foreground">
              {sending
                ? "Sending"
                : run.status === "running"
                  ? "Agents working"
                  : run.status === "awaiting_approval"
                    ? "Waiting for your approval"
                    : "Ready to continue"}
            </span>
            <PromptInputSubmit
              aria-label="Send instructions"
              disabled={!reply.trim() || sending || run.status === "failed"}
            >
              <ArrowUp />
            </PromptInputSubmit>
          </PromptInputFooter>
        </PromptInput>
      </div>

      {files.length > 0 && (
        <div className="mt-6 rounded-lg border border-border bg-card">
          <div className="flex flex-wrap items-center gap-2 border-b border-border p-3">
            <span className="font-mono text-xs text-muted-foreground">PROJECT FILES</span>
            {files.map((f) => (
              <Button
                type="button"
                size="sm"
                variant={current?.path === f.path ? "default" : "secondary"}
                key={f.id}
                onClick={() => setFile(f.path)}
                className={`inline-flex items-center gap-1 rounded px-2 py-1 font-mono text-xs ${current?.path === f.path ? "bg-primary text-primary-foreground" : "bg-secondary"}`}
              >
                <FileCode className="h-3 w-3" /> {f.path}
              </Button>
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
          <MessageResponse className="mt-3 text-sm leading-relaxed">{run.output}</MessageResponse>
        </div>
      )}
    </div>
  );
}
