import { streamText, tool, isStepCount, type ToolSet } from "ai";
import { z } from "zod";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";
import { resolveModel, type Settings } from "./ai-provider.server";
import { appendFollowUps, unseenFollowUps } from "./continuous-work";

type Db = SupabaseClient<Database>;
type Agent = Database["public"]["Tables"]["agents"]["Row"];
export type Stage = { agent_ids: string[] };

async function webSearch(query: string) {
  const res = await fetch("https://html.duckduckgo.com/html/?q=" + encodeURIComponent(query), {
    headers: { "User-Agent": "Mozilla/5.0 (compatible; AgentStudio/1.0)" },
  });
  const html = await res.text();
  const results: { title: string; url: string; snippet: string }[] = [];
  const re =
    /<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>[\s\S]*?class="result__snippet"[^>]*>([\s\S]*?)<\/a>/g;
  const strip = (s: string) =>
    s
      .replace(/<[^>]+>/g, "")
      .replace(/&amp;/g, "&")
      .replace(/&quot;/g, '"')
      .replace(/&#x27;/g, "'")
      .trim();
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) && results.length < 6) {
    let url = m[1] ?? "";
    const u = url.match(/uddg=([^&]+)/);
    if (u?.[1]) url = decodeURIComponent(u[1]);
    results.push({ title: strip(m[2] ?? ""), url, snippet: strip(m[3] ?? "") });
  }
  return results;
}

async function readPage(url: string) {
  const res = await fetch(url, {
    headers: { "User-Agent": "Mozilla/5.0 (compatible; AgentStudio/1.0)" },
  });
  const html = await res.text();
  return html
    .replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>/gi, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .slice(0, 8000);
}

export async function executeRun(opts: {
  db: Db;
  userId: string;
  runId: string;
  stages: Stage[];
  agents: Agent[];
  input: string;
  settings: Settings | null;
}) {
  const { db, userId, runId, stages, agents, input, settings } = opts;
  const delivered = new Set<number>();
  const readReplies = async () => {
    const { data, error } = await db.from("run_logs").select("id, message, created_at").eq("run_id", runId).eq("kind", "user_message").order("created_at").order("id");
    if (error) throw new Error(error.message);
    return data ?? [];
  };

  const log = async (agent_name: string, kind: string, message: string) => {
    await db.from("run_logs").insert({
      run_id: runId,
      user_id: userId,
      agent_name,
      kind,
      message: message.slice(0, 20000),
    });
  };

  const knowledgeTools = (agentName: string): ToolSet => ({
    save_knowledge: tool({
      description:
        "Save a reusable lesson, fact or method to the shared knowledge library so every other agent can learn it.",
      inputSchema: z.object({ topic: z.string(), content: z.string() }),
      execute: async ({ topic, content }) => {
        await db
          .from("knowledge")
          .insert({ user_id: userId, agent_name: agentName, topic, content });
        await log(agentName, "knowledge", `Learned: ${topic}`);
        return { saved: true };
      },
    }),
    search_knowledge: tool({
      description: "Search the shared knowledge library that all agents contribute to.",
      inputSchema: z.object({ query: z.string() }),
      execute: async ({ query }) => {
        const { data } = await db
          .from("knowledge")
          .select("topic, content, agent_name")
          .or(
            `topic.ilike.%${query.replace(/[%,()]/g, " ")}%,content.ilike.%${query.replace(/[%,()]/g, " ")}%`,
          )
          .limit(8);
        await log(agentName, "tool", `Searched knowledge: "${query}" (${data?.length ?? 0} found)`);
        return data ?? [];
      },
    }),
  });

  const runAgent = async (
    name: string,
    systemPrompt: string,
    skills: string[],
    task: string,
    depth: number,
    aiProvider: string,
  ): Promise<string> => {
    const ai = resolveModel(settings, aiProvider);
    const tools: ToolSet = { ...knowledgeTools(name) };
    if (skills.includes("web_search")) {
      tools["web_search"] = tool({
        description: "Search the web. Returns titles, URLs and snippets.",
        inputSchema: z.object({ query: z.string() }),
        execute: async ({ query }) => {
          await log(name, "tool", `Web search: "${query}"`);
          try {
            return await webSearch(query);
          } catch {
            return { error: "Search failed" };
          }
        },
      });
      tools["read_page"] = tool({
        description: "Read the text of a web page.",
        inputSchema: z.object({ url: z.string() }),
        execute: async ({ url }) => {
          await log(name, "tool", `Reading ${url}`);
          try {
            return await readPage(url);
          } catch {
            return "Could not read page";
          }
        },
      });
    }
    if (skills.includes("build")) {
      tools["write_file"] = tool({
        description:
          "Create or overwrite a project file (e.g. index.html, game.js, styles.css, main.py, song.md). For playable web games/apps, put everything needed in index.html (inline CSS/JS) so it previews live. Write complete, working code — never placeholders.",
        inputSchema: z.object({ path: z.string(), content: z.string() }),
        execute: async ({ path, content }) => {
          const { error } = await db.from("artifacts").upsert(
            {
              user_id: userId,
              run_id: runId,
              agent_name: name,
              path,
              content,
              updated_at: new Date().toISOString(),
            },
            { onConflict: "run_id,path" },
          );
          await log(
            name,
            "file",
            `${error ? "Failed to write" : "Wrote"} ${path} (${content.length} chars)`,
          );
          return error ? { error: error.message } : { saved: path };
        },
      });
      tools["read_file"] = tool({
        description: "Read a project file written earlier in this run by any agent.",
        inputSchema: z.object({ path: z.string() }),
        execute: async ({ path }) => {
          const { data } = await db
            .from("artifacts")
            .select("content")
            .eq("run_id", runId)
            .eq("path", path)
            .maybeSingle();
          return data?.content ?? "File not found";
        },
      });
      tools["list_files"] = tool({
        description: "List project files written in this run.",
        inputSchema: z.object({}),
        execute: async () => {
          const { data } = await db
            .from("artifacts")
            .select("path, agent_name")
            .eq("run_id", runId);
          return data ?? [];
        },
      });
    }
    if (skills.includes("create_helper") && depth < 2) {
      tools["create_helper_agent"] = tool({
        description:
          "Create a new specialist AI agent to learn or handle a sub-task you lack expertise in. It runs immediately and returns its answer. Set save=true to keep it in the agent roster.",
        inputSchema: z.object({
          name: z.string(),
          role: z.string(),
          system_prompt: z.string(),
          task: z.string(),
          save: z.boolean(),
        }),
        execute: async (h) => {
          await log(name, "helper", `Created helper "${h.name}" (${h.role})`);
          if (h.save) {
            await db.from("agents").insert({
              user_id: userId,
              name: h.name,
              role: h.role,
              system_prompt: h.system_prompt,
              skills: ["write", "web_search"],
              color: "violet",
            });
          }
          return await runAgent(
            h.name,
            h.system_prompt,
            ["write", "web_search", ...(skills.includes("build") ? ["build"] : [])],
            h.task,
            depth + 1,
            aiProvider,
          );
        },
      });
    }

    const { data: recent } = await db
      .from("knowledge")
      .select("topic, content, agent_name")
      .order("created_at", { ascending: false })
      .limit(12);
    const knowledgeBlock = recent?.length
      ? `\n\nShared knowledge from the team (learned so far):\n${recent.map((k) => `- [${k.agent_name}] ${k.topic}: ${k.content.slice(0, 300)}`).join("\n")}`
      : "";
    const structured = skills.includes("structured")
      ? "\n\nWhen useful, include structured results as a fenced ```json block (array of objects) so the next agent can use them."
      : "";

    const instructions = `${systemPrompt || `You are ${name}.`}

You are one agent in a coordinated team. Do your part thoroughly and hand off clear output. Whenever you discover a reusable fact, method or lesson, call save_knowledge so teammates gain it. Check search_knowledge before redoing work.${structured}${knowledgeBlock}`;

    await log(name, "start", `Working on task`);
    const seen = new Set<number>();
    let messages = [{ role: "user" as const, content: task }] as import("ai").ModelMessage[];
    let text = "";
    do {
    const result = streamText({
      model: ai.model,
      instructions,
      messages,
      prepareStep: async ({ messages: current }) => {
        const fresh = unseenFollowUps(await readReplies(), seen);
        for (const reply of fresh) { seen.add(reply.id); delivered.add(reply.id); }
        if (fresh.length) {
          await log(name, "steering", `Received ${fresh.length} follow-up${fresh.length === 1 ? "" : "s"}`);
          return { messages: appendFollowUps(current, fresh) };
        }
        return {};
      },
      tools,
      stopWhen: isStepCount(50),
      maxRetries: 0,
      ...(ai.providerOptions ? { providerOptions: ai.providerOptions } : {}),
    });
    text = await result.text;
    // The model may finish a text-only step; keep its complete tool/history pairs
    // and continue if a reply arrived while that step was streaming.
    const response = await result.response;
    messages = [...messages, ...response.messages];
    const fresh = unseenFollowUps(await readReplies(), seen);
    if (!fresh.length) break;
    for (const reply of fresh) { seen.add(reply.id); delivered.add(reply.id); }
    messages = appendFollowUps(messages, fresh);
    } while (true);
    await log(name, "output", text || "(no output)");
    return text;
  };

  try {
    let carry = "";
    for (let i = 0; i < stages.length; i++) {
      const stageAgents = (stages[i]?.agent_ids ?? []).map((id) => agents.find((a) => a.id === id)).filter(
        (a): a is Agent => !!a,
      );
      if (!stageAgents.length) continue;
      await log("system", "stage", `Stage ${i + 1}: ${stageAgents.map((a) => a.name).join(", ")}`);
      const task = carry
        ? `Overall goal:\n${input}\n\nOutput from the previous stage:\n${carry}\n\nNow do your part.`
        : input;
      const outputs = await Promise.all(
        stageAgents.map((a) =>
          runAgent(
            a.name,
            `${a.role ? `Role: ${a.role}\n` : ""}${a.system_prompt}`,
            a.skills,
            task,
            0,
            a.provider,
          ).then((t) => `## ${a.name}\n${t}`),
        ),
      );
      carry = outputs.join("\n\n");
    }
    // Seal completion, then check the inbox: replies arriving at the boundary
    // are handled here; later replies reopen the run through sendRunReply.
    await db
      .from("runs")
      .update({ status: "completed", output: carry, finished_at: new Date().toISOString() })
      .eq("id", runId);
    const remaining = unseenFollowUps(await readReplies(), delivered);
    if (remaining.length) {
      await db.from("runs").update({ status: "running", finished_at: null }).eq("id", runId);
      await executeRun({ ...opts, input: `${input}\n\nPrevious work:\n${carry}` });
      return;
    }
    await log("system", "done", "Workflow completed");
  } catch (e) {
    const err = e as { statusCode?: number; message?: string };
    const msg =
      err.statusCode === 402
        ? "Out of AI credits. Add credits, or switch agents to Ollama or your own key in Settings."
        : err.statusCode === 429
          ? "Rate limited. Please try again in a moment."
          : err.message || "Run failed";
    console.error(e);
    await log("system", "error", msg);
    await db
      .from("runs")
      .update({ status: "failed", output: msg, finished_at: new Date().toISOString() })
      .eq("id", runId);
  }
}
