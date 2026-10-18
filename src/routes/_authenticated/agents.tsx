import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { Plus, Pencil, Trash2 } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import type { Database } from "@/integrations/supabase/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { SKILLS, COLORS, colorClass } from "@/lib/skills";

type Agent = Database["public"]["Tables"]["agents"]["Row"];

export const Route = createFileRoute("/_authenticated/agents")({
  head: () => ({ meta: [{ title: "Agents — Hive" }, { name: "description", content: "Create and configure AI agents." }] }),
  component: AgentsPage,
});

export function useAgents() {
  return useQuery({
    queryKey: ["agents"],
    queryFn: async () => {
      const { data, error } = await supabase.from("agents").select("*").order("created_at");
      if (error) throw error;
      return data;
    },
  });
}

const empty = { name: "", role: "", system_prompt: "", skills: ["write"] as string[], color: "amber" };

function AgentsPage() {
  const { data: agents = [] } = useAgents();
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Agent | null>(null);
  const [form, setForm] = useState(empty);

  const startNew = () => { setEditing(null); setForm(empty); setOpen(true); };
  const startEdit = (a: Agent) => { setEditing(a); setForm({ name: a.name, role: a.role, system_prompt: a.system_prompt, skills: a.skills, color: a.color }); setOpen(true); };

  const save = async () => {
    if (!form.name.trim()) { toast.error("Give the agent a name"); return; }
    const { error } = editing
      ? await supabase.from("agents").update(form).eq("id", editing.id)
      : await supabase.from("agents").insert(form);
    if (error) { toast.error(error.message); return; }
    setOpen(false);
    qc.invalidateQueries({ queryKey: ["agents"] });
  };
  const remove = async (id: string) => {
    const { error } = await supabase.from("agents").delete().eq("id", id);
    if (error) { toast.error(error.message); return; }
    qc.invalidateQueries({ queryKey: ["agents"] });
  };

  return (
    <div>
      <div className="flex items-end justify-between">
        <div>
          <div className="font-mono text-xs text-primary">ROSTER</div>
          <h1 className="text-3xl font-bold">Agents</h1>
        </div>
        <Button onClick={startNew}><Plus className="h-4 w-4" /> New agent</Button>
      </div>
      <div className="mt-8 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {agents.map((a) => (
          <div key={a.id} className="rounded-lg border border-border bg-card p-5">
            <div className="flex items-start justify-between gap-2">
              <div className="flex items-center gap-3">
                <span className={`h-3 w-3 rounded-sm ${colorClass[a.color] ?? "bg-primary"}`} />
                <div>
                  <div className="font-semibold">{a.name}</div>
                  <div className="text-sm text-muted-foreground">{a.role || "No role"}</div>
                </div>
              </div>
              <div className="flex gap-1">
                <Button size="icon" variant="ghost" onClick={() => startEdit(a)} aria-label="Edit"><Pencil className="h-4 w-4" /></Button>
                <Button size="icon" variant="ghost" onClick={() => remove(a.id)} aria-label="Delete"><Trash2 className="h-4 w-4" /></Button>
              </div>
            </div>
            <p className="mt-3 line-clamp-3 text-sm text-muted-foreground">{a.system_prompt || "—"}</p>
            <div className="mt-3 flex flex-wrap gap-1">
              {a.skills.map((s) => (
                <span key={s} className="rounded bg-secondary px-2 py-0.5 font-mono text-xs">{SKILLS.find((k) => k.id === s)?.label ?? s}</span>
              ))}
            </div>
          </div>
        ))}
        {!agents.length && <p className="text-muted-foreground">No agents yet — create your first one.</p>}
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader><DialogTitle>{editing ? "Edit agent" : "New agent"}</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <div><Label>Name</Label><Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Researcher" /></div>
            <div><Label>Role</Label><Input value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })} placeholder="Finds and verifies facts" /></div>
            <div><Label>System prompt</Label><Textarea rows={5} value={form.system_prompt} onChange={(e) => setForm({ ...form, system_prompt: e.target.value })} placeholder="You are a meticulous researcher..." /></div>
            <div>
              <Label>Skills</Label>
              <div className="mt-2 space-y-2">
                {SKILLS.map((s) => (
                  <label key={s.id} className="flex items-start gap-3 text-sm">
                    <Checkbox checked={form.skills.includes(s.id)} onCheckedChange={(c) => setForm({ ...form, skills: c ? [...form.skills, s.id] : form.skills.filter((x) => x !== s.id) })} />
                    <span><span className="font-medium">{s.label}</span> <span className="text-muted-foreground">— {s.desc}</span></span>
                  </label>
                ))}
                <p className="text-xs text-muted-foreground">Every agent can read and add to the shared knowledge library.</p>
              </div>
            </div>
            <div>
              <Label>Color</Label>
              <div className="mt-2 flex gap-2">
                {COLORS.map((c) => (
                  <button key={c} type="button" aria-label={c} onClick={() => setForm({ ...form, color: c })} className={`h-6 w-6 rounded ${colorClass[c]} ${form.color === c ? "ring-2 ring-ring ring-offset-2 ring-offset-background" : ""}`} />
                ))}
              </div>
            </div>
            <Button className="w-full" onClick={save}>Save agent</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
