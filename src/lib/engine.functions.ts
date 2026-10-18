import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { executeRun, type Stage } from "./engine.server";
import { loadSettings } from "./ai-provider.server";

export const createRun = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: { workflowId: string; input: string }) => d)
  .handler(async ({ data, context }) => {
    const db = context.supabase;
    const { data: wf, error } = await db.from("workflows").select("id, name").eq("id", data.workflowId).single();
    if (error || !wf) throw new Error("Workflow not found");
    const { data: run, error: runErr } = await db
      .from("runs")
      .insert({ user_id: context.userId, workflow_id: wf.id, workflow_name: wf.name, input: data.input })
      .select("id")
      .single();
    if (runErr || !run) throw new Error(runErr?.message ?? "Could not start run");
    return { runId: run.id };
  });

export const executeRunFn = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: { runId: string }) => d)
  .handler(async ({ data, context }) => {
    const db = context.supabase;
    const { data: run } = await db.from("runs").select("*").eq("id", data.runId).single();
    if (!run || run.status !== "running" || !run.workflow_id) throw new Error("Run not available");
    const { data: wf } = await db.from("workflows").select("stages").eq("id", run.workflow_id).single();
    const { data: agents } = await db.from("agents").select("*");
    await executeRun({
      db, userId: context.userId, runId: run.id,
      stages: ((wf?.stages ?? []) as unknown as Stage[]), agents: agents ?? [], input: run.input,
      settings: await loadSettings(db, context.userId),
    });
    return { ok: true };
  });
