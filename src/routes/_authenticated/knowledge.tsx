import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";
import { Trash2 } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";

export const Route = createFileRoute("/_authenticated/knowledge")({
  head: () => ({ meta: [{ title: "Knowledge — Hive" }, { name: "description", content: "Shared knowledge all agents learn from." }] }),
  component: KnowledgePage,
});

function KnowledgePage() {
  const qc = useQueryClient();
  const { data = [] } = useQuery({
    queryKey: ["knowledge"],
    queryFn: async () => {
      const { data, error } = await supabase.from("knowledge").select("*").order("created_at", { ascending: false });
      if (error) throw error;
      return data;
    },
  });
  const [topic, setTopic] = useState("");
  const [content, setContent] = useState("");
  const [q, setQ] = useState("");

  const add = async () => {
    if (!topic || !content) return;
    const { error } = await supabase.from("knowledge").insert({ topic, content, agent_name: "You" });
    if (error) return toast.error(error.message);
    setTopic(""); setContent("");
    qc.invalidateQueries({ queryKey: ["knowledge"] });
  };
  const remove = async (id: string) => {
    await supabase.from("knowledge").delete().eq("id", id);
    qc.invalidateQueries({ queryKey: ["knowledge"] });
  };
  const shown = data.filter((k) => !q || (k.topic + k.content).toLowerCase().includes(q.toLowerCase()));

  return (
    <div>
      <div className="font-mono text-xs text-primary">HIVE MIND</div>
      <h1 className="text-3xl font-bold">Shared knowledge</h1>
      <p className="mt-2 text-muted-foreground">Everything agents learn lands here, and every agent reads it before working.</p>
      <div className="mt-6 grid gap-2 rounded-lg border border-border bg-card p-4 md:grid-cols-[1fr_2fr_auto]">
        <Input placeholder="Topic" value={topic} onChange={(e) => setTopic(e.target.value)} />
        <Textarea rows={1} placeholder="What should every agent know?" value={content} onChange={(e) => setContent(e.target.value)} />
        <Button onClick={add}>Teach</Button>
      </div>
      <Input className="mt-6 max-w-xs" placeholder="Search knowledge" value={q} onChange={(e) => setQ(e.target.value)} />
      <div className="mt-4 space-y-2">
        {shown.map((k) => (
          <div key={k.id} className="flex items-start justify-between gap-4 rounded-lg border border-border bg-card p-4">
            <div>
              <div className="font-semibold">{k.topic}</div>
              <p className="mt-1 whitespace-pre-wrap text-sm text-muted-foreground">{k.content}</p>
              <div className="mt-2 font-mono text-xs text-accent">from {k.agent_name || "unknown"} · {new Date(k.created_at).toLocaleString()}</div>
            </div>
            <Button size="icon" variant="ghost" aria-label="Delete" onClick={() => remove(k.id)}><Trash2 className="h-4 w-4" /></Button>
          </div>
        ))}
        {!shown.length && <p className="text-muted-foreground">Nothing learned yet.</p>}
      </div>
    </div>
  );
}
