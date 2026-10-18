import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Plus, Trash2, ChevronRight, X } from "lucide-react";
import { db as supabase } from "@/lib/db";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { colorClass, type Stage } from "@/lib/skills";
import { useAgents } from "./agents";

export const Route = createFileRoute("/_authenticated/workflows")({
  head: () => ({
    meta: [
      { title: "Workflows — Tensai" },
      { name: "description", content: "Chain agents into workflows." },
      { property: "og:title", content: "Workflows — Tensai" },
      { property: "og:description", content: "Chain agents into workflows." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: WorkflowsPage,
});

export function useWorkflows() {
  return useQuery({
    queryKey: ["workflows"],
    queryFn: async () => {
      const { data, error } = await supabase.from("workflows").select("*").order("created_at");
      if (error) throw error;
      return data.map((w) => ({ ...w, stages: (w.stages as unknown as Stage[]) ?? [] }));
    },
  });
}

function WorkflowsPage() {
  const { data: workflows = [] } = useWorkflows();
  const { data: agents = [] } = useAgents();
  const qc = useQueryClient();
  const [selected, setSelected] = useState<string | null>(null);
  const wf = workflows.find((w) => w.id === selected);
  const [name, setName] = useState("");
  const [desc, setDesc] = useState("");
  const [stages, setStages] = useState<Stage[]>([]);

  useEffect(() => {
    if (wf) {
      setName(wf.name);
      setDesc(wf.description);
      setStages(wf.stages);
    }
  }, [wf?.id]); // eslint-disable-line react-hooks/exhaustive-deps

  const create = async () => {
    const { data, error } = await supabase
      .from("workflows")
      .insert({ name: "New workflow", stages: [{ agent_ids: [] }] })
      .select("id")
      .single();
    if (error) {
      toast.error(error.message);
      return;
    }
    await qc.invalidateQueries({ queryKey: ["workflows"] });
    setSelected(data.id);
  };
  const save = async () => {
    if (!wf) return;
    const { error } = await supabase
      .from("workflows")
      .update({ name, description: desc, stages: stages as never })
      .eq("id", wf.id);
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success("Workflow saved");
    qc.invalidateQueries({ queryKey: ["workflows"] });
  };
  const remove = async () => {
    if (!wf) return;
    await supabase.from("workflows").delete().eq("id", wf.id);
    setSelected(null);
    qc.invalidateQueries({ queryKey: ["workflows"] });
  };

  const addAgent = (i: number, id: string) =>
    setStages(
      stages.map((s, j) =>
        j === i && !s.agent_ids.includes(id) ? { agent_ids: [...s.agent_ids, id] } : s,
      ),
    );
  const removeAgent = (i: number, id: string) =>
    setStages(
      stages.map((s, j) => (j === i ? { agent_ids: s.agent_ids.filter((x) => x !== id) } : s)),
    );

  return (
    <div>
      <div className="flex items-end justify-between">
        <div>
          <div className="font-mono text-xs text-primary">PIPELINES</div>
          <h1 className="text-3xl font-bold">Workflows</h1>
        </div>
        <Button onClick={create}>
          <Plus className="h-4 w-4" /> New workflow
        </Button>
      </div>
      <div className="mt-6 flex flex-wrap gap-2">
        {workflows.map((w) => (
          <button
            key={w.id}
            onClick={() => setSelected(w.id)}
            className={`rounded-md border px-3 py-1.5 text-sm ${selected === w.id ? "border-primary bg-primary/10 text-foreground" : "border-border text-muted-foreground hover:text-foreground"}`}
          >
            {w.name}
          </button>
        ))}
        {!workflows.length && <p className="text-muted-foreground">No workflows yet.</p>}
      </div>

      {wf && (
        <div className="mt-8 space-y-4">
          <div className="grid gap-3 md:grid-cols-2">
            <Input value={name} onChange={(e) => setName(e.target.value)} />
            <Textarea
              rows={1}
              value={desc}
              onChange={(e) => setDesc(e.target.value)}
              placeholder="What does this workflow do?"
            />
          </div>
          <p className="text-sm text-muted-foreground">
            Stages run left to right. Agents in the same stage work side by side; the next stage
            receives all their outputs.
          </p>
          <div className="flex items-stretch gap-2 overflow-x-auto pb-4">
            {stages.map((s, i) => (
              <div key={i} className="flex items-center gap-2">
                <div className="w-64 shrink-0 rounded-lg border border-border bg-card p-3">
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs text-primary">STAGE {i + 1}</span>
                    <button
                      aria-label="Remove stage"
                      onClick={() => setStages(stages.filter((_, j) => j !== i))}
                      className="text-muted-foreground hover:text-destructive"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                  <div className="mt-3 space-y-2">
                    {s.agent_ids.map((id) => {
                      const a = agents.find((x) => x.id === id);
                      return (
                        <div
                          key={id}
                          className="flex items-center justify-between rounded-md border border-border bg-secondary px-2 py-1.5 text-sm"
                        >
                          <span className="flex items-center gap-2">
                            <span
                              className={`h-2.5 w-2.5 rounded-sm ${colorClass[a?.color ?? ""] ?? "bg-primary"}`}
                            />
                            {a?.name ?? "Missing agent"}
                          </span>
                          <button
                            aria-label="Remove agent"
                            onClick={() => removeAgent(i, id)}
                            className="text-muted-foreground hover:text-foreground"
                          >
                            <X className="h-3 w-3" />
                          </button>
                        </div>
                      );
                    })}
                    <Select value="" onValueChange={(v) => addAgent(i, v)}>
                      <SelectTrigger className="h-8 text-xs">
                        <SelectValue placeholder="+ Add agent" />
                      </SelectTrigger>
                      <SelectContent>
                        {agents.map((a) => (
                          <SelectItem key={a.id} value={a.id}>
                            {a.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-muted-foreground" />
              </div>
            ))}
            <button
              onClick={() => setStages([...stages, { agent_ids: [] }])}
              className="w-40 shrink-0 rounded-lg border border-dashed border-border text-sm text-muted-foreground hover:border-primary hover:text-primary"
            >
              + Add stage
            </button>
          </div>
          <div className="flex gap-2">
            <Button onClick={save}>Save workflow</Button>
            <Button variant="ghost" onClick={remove}>
              <Trash2 className="h-4 w-4" /> Delete
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
