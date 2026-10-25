import { createServerFn } from "@tanstack/react-start";
import { requireAppAuth } from "./app-auth";
import { executeRun, type Stage } from "./engine.server";
import { loadSettings } from "./ai-provider.server";
import { z } from "zod";
import { inputWithPlan, modeForStatus, type RunMode } from "./plan-mode";

export const sendRunReply = createServerFn({ method: "POST" })
  .middleware([requireAppAuth])
  .inputValidator(
    z.object({ runId: z.string().uuid(), message: z.string().trim().min(1).max(20000) }),
  )
  .handler(async ({ data, context }) => {
    const db = context.supabase;
    const { data: run } = await db
      .from("runs")
      .select("*")
      .eq("id", data.runId)
      .eq("user_id", context.userId)
      .single();
    if (!run || !run.workflow_id) throw new Error("Run not available");
    if (run.status === "failed") throw new Error("Start a new run after resolving the error.");
    const { error } = await db.from("run_logs").insert({
      run_id: run.id,
      user_id: context.userId,
      agent_name: "You",
      kind: "user_message",
      message: data.message,
    });
    if (error) throw new Error(error.message);
    // Compare-and-set prevents two replies from launching two continuations.
    // A reply to a pending plan sends the run back to planning.
    const pending = run.status === "awaiting_approval";
    const from = pending ? "awaiting_approval" : "completed";
    const { data: resumed, error: resumeError } = await db
      .from("runs")
      .update({ status: pending ? "planning" : "running", finished_at: null })
      .eq("id", run.id)
      .eq("status", from)
      .select("id");
    if (resumeError) throw new Error(resumeError.message);
    return { resume: Boolean(resumed?.length) };
  });

export const createRun = createServerFn({ method: "POST" })
  .middleware([requireAppAuth])
  .inputValidator((d: { workflowId: string; input: string; mode?: RunMode }) => d)
  .handler(async ({ data, context }) => {
    const db = context.supabase;
    const { data: wf, error } = await db
      .from("workflows")
      .select("id, name")
      .eq("id", data.workflowId)
      .single();
    if (error || !wf) throw new Error("Workflow not found");
    const { data: run, error: runErr } = await db
      .from("runs")
      .insert({
        user_id: context.userId,
        workflow_id: wf.id,
        workflow_name: wf.name,
        input: data.input,
        status: data.mode === "plan" ? "planning" : "running",
      })
      .select("id")
      .single();
    if (runErr || !run) throw new Error(runErr?.message ?? "Could not start run");
    return { runId: run.id };
  });

export const executeRunFn = createServerFn({ method: "POST" })
  .middleware([requireAppAuth])
  .inputValidator((d: { runId: string }) => d)
  .handler(async ({ data, context }) => {
    const db = context.supabase;
    const { data: run } = await db.from("runs").select("*").eq("id", data.runId).single();
    if (!run || !["running", "planning"].includes(run.status) || !run.workflow_id)
      throw new Error("Run not available");
    const mode = modeForStatus(run.status);
    const { data: planLog } = await db
      .from("run_logs")
      .select("message")
      .eq("run_id", run.id)
      .eq("kind", "plan")
      .order("created_at", { ascending: false })
      .order("id", { ascending: false })
      .limit(1)
      .maybeSingle();
    const { data: wf } = await db
      .from("workflows")
      .select("stages")
      .eq("id", run.workflow_id)
      .single();
    const { data: agents } = await db.from("agents").select("*");
    await executeRun({
      db,
      userId: context.userId,
      runId: run.id,
      stages: (wf?.stages ?? []) as unknown as Stage[],
      agents: agents ?? [],
      input: inputWithPlan(run.input, planLog?.message ?? null, mode, run.output),
      settings: await loadSettings(db, context.userId),
      mode,
    });
    return { ok: true };
  });

export const approvePlan = createServerFn({ method: "POST" })
  .middleware([requireAppAuth])
  .inputValidator(
    z.object({ runId: z.string().uuid(), plan: z.string().trim().min(1).max(60000).optional() }),
  )
  .handler(async ({ data, context }) => {
    const db = context.supabase;
    // Compare-and-set so a double click cannot start two executions.
    const { data: approved, error } = await db
      .from("runs")
      .update({ status: "running", finished_at: null })
      .eq("id", data.runId)
      .eq("user_id", context.userId)
      .eq("status", "awaiting_approval")
      .select("id");
    if (error) throw new Error(error.message);
    if (!approved?.length) throw new Error("This run is not waiting for approval.");
    // An edited plan becomes the newest plan log, which is the one the run follows.
    if (data.plan)
      await db.from("run_logs").insert({
        run_id: data.runId,
        user_id: context.userId,
        agent_name: "You",
        kind: "plan",
        message: data.plan,
      });
    await db.from("run_logs").insert({
      run_id: data.runId,
      user_id: context.userId,
      agent_name: "You",
      kind: "info",
      message: data.plan ? "Plan edited and approved" : "Plan approved",
    });
    return { resume: true };
  });

export const rejectPlan = createServerFn({ method: "POST" })
  .middleware([requireAppAuth])
  .inputValidator(z.object({ runId: z.string().uuid() }))
  .handler(async ({ data, context }) => {
    const db = context.supabase;
    const { data: rejected, error } = await db
      .from("runs")
      .update({ status: "failed", output: "Plan rejected", finished_at: new Date().toISOString() })
      .eq("id", data.runId)
      .eq("user_id", context.userId)
      .eq("status", "awaiting_approval")
      .select("id");
    if (error) throw new Error(error.message);
    if (!rejected?.length) throw new Error("This run is not waiting for approval.");
    await db.from("run_logs").insert({
      run_id: data.runId,
      user_id: context.userId,
      agent_name: "You",
      kind: "info",
      message: "Plan rejected",
    });
    return { ok: true };
  });
