import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { executeRun, type Stage } from "./engine.server";

export const startRun = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: { workflowId: string; input: string }) => d)
  .handler(async ({ data, context }) => {
    const db = context.supabase;
    const apiKey = process.env.LOVABLE_API_KEY;
    if (!apiKey) throw new Error("AI is not configured");
    const { data: wf, error } = await db.from("workflows").select("*").eq("id", data.workflowId).single();
    if (error || !wf) throw new Error("Workflow not found");
    const { data: agents } = await db.from("agents").select("*");
    const { data: run, error: runErr } = await db
      .from("runs")
      .insert({ user_id: context.userId, workflow_id: wf.id, workflow_name: wf.name, input: data.input })
      .select("id")
      .single();
    if (runErr || !run) throw new Error(runErr?.message ?? "Could not start run");
    await executeRun({
      db, userId: context.userId, runId: run.id,
      stages: (wf.stages as unknown as Stage[]) ?? [], agents: agents ?? [], input: data.input, apiKey,
    });
    return { runId: run.id };
  });
