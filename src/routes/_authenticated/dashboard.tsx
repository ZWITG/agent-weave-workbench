import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Play } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { createRun, executeRunFn } from "@/lib/engine.functions";
import { useAgents } from "./agents";
import { useWorkflows } from "./workflows";

export const Route = createFileRoute("/_authenticated/dashboard")({
  head: () => ({
    meta: [
      { title: "Control room — Hive" },
      { name: "description", content: "Run workflows and track agent output." },
      { property: "og:title", content: "Control room — Hive" },
      { property: "og:description", content: "Run workflows and track agent output." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: Dashboard,
});

export function StatusDot({ status }: { status: string }) {
  const c =
    status === "completed"
      ? "bg-success"
      : status === "failed"
        ? "bg-destructive"
        : "bg-primary animate-pulse";
  return <span className={`inline-block h-2 w-2 rounded-full ${c}`} />;
}

function Dashboard() {
  const { data: agents = [] } = useAgents();
  const { data: workflows = [] } = useWorkflows();
  const qc = useQueryClient();
  const navigate = useNavigate();
  const create = useServerFn(createRun);
  const execute = useServerFn(executeRunFn);
  const [wfId, setWfId] = useState("");
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);

  const { data: runs = [] } = useQuery({
    queryKey: ["runs"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("runs")
        .select("*")
        .order("started_at", { ascending: false })
        .limit(30);
      if (error) throw error;
      return data;
    },
  });
  const { data: knowledgeCount = 0 } = useQuery({
    queryKey: ["knowledge-count"],
    queryFn: async () =>
      (await supabase.from("knowledge").select("id", { count: "exact", head: true })).count ?? 0,
  });

  useEffect(() => {
    const ch = supabase
      .channel("runs-dash")
      .on("postgres_changes", { event: "*", schema: "public", table: "runs" }, () => {
        qc.invalidateQueries({ queryKey: ["runs"] });
        qc.invalidateQueries({ queryKey: ["knowledge-count"] });
      })
      .subscribe();
    return () => {
      supabase.removeChannel(ch);
    };
  }, [qc]);

  const start = async () => {
    if (!wfId || !input.trim()) {
      toast.error("Pick a workflow and describe the task");
      return;
    }
    setBusy(true);
    try {
      const { runId } = await create({ data: { workflowId: wfId, input } });
      execute({ data: { runId } }).catch((e) => toast.error(e.message));
      navigate({ to: "/runs/$runId", params: { runId } });
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  const active = runs.filter((r) => r.status === "running").length;
  const stats = [
    { l: "Agents", v: agents.length },
    { l: "Workflows", v: workflows.length },
    { l: "Active runs", v: active },
    { l: "Knowledge", v: knowledgeCount },
  ];

  return (
    <div>
      <div className="font-mono text-xs text-primary">CONTROL ROOM</div>
      <h1 className="text-3xl font-bold">Dashboard</h1>
      <div className="mt-6 grid grid-cols-2 gap-3 md:grid-cols-4">
        {stats.map((s) => (
          <div key={s.l} className="rounded-lg border border-border bg-card p-4">
            <div className="font-mono text-3xl font-semibold">{s.v}</div>
            <div className="text-sm text-muted-foreground">{s.l}</div>
          </div>
        ))}
      </div>

      <div className="mt-8 rounded-lg border border-primary/40 bg-card p-5">
        <h2 className="font-semibold">Launch a run</h2>
        {!workflows.length ? (
          <p className="mt-2 text-sm text-muted-foreground">
            Create{" "}
            <Link to="/agents" className="text-primary underline">
              agents
            </Link>{" "}
            and a{" "}
            <Link to="/workflows" className="text-primary underline">
              workflow
            </Link>{" "}
            first.
          </p>
        ) : (
          <div className="mt-3 space-y-3">
            <Select value={wfId} onValueChange={setWfId}>
              <SelectTrigger className="md:w-80">
                <SelectValue placeholder="Choose workflow" />
              </SelectTrigger>
              <SelectContent>
                {workflows.map((w) => (
                  <SelectItem key={w.id} value={w.id}>
                    {w.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Textarea
              rows={3}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="e.g. Build a playable snake game with a neon theme"
            />
            <Button onClick={start} disabled={busy}>
              <Play className="h-4 w-4" /> Run workflow
            </Button>
          </div>
        )}
      </div>

      <h2 className="mt-10 font-semibold">Recent runs</h2>
      <div className="mt-3 divide-y divide-border rounded-lg border border-border bg-card">
        {runs.map((r) => (
          <Link
            key={r.id}
            to="/runs/$runId"
            params={{ runId: r.id }}
            className="flex items-center gap-4 p-4 hover:bg-secondary"
          >
            <StatusDot status={r.status} />
            <div className="min-w-0 flex-1">
              <div className="truncate font-medium">{r.input}</div>
              <div className="font-mono text-xs text-muted-foreground">
                {r.workflow_name} · {new Date(r.started_at).toLocaleString()}
              </div>
            </div>
            <span className="font-mono text-xs uppercase text-muted-foreground">{r.status}</span>
          </Link>
        ))}
        {!runs.length && <p className="p-4 text-sm text-muted-foreground">No runs yet.</p>}
      </div>
    </div>
  );
}
