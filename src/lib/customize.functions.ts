import { createServerFn } from "@tanstack/react-start";
import { generateText } from "ai";
import { requireAppAuth } from "./app-auth";
import { loadSettings, resolveModel } from "./ai-provider.server";
import { configSchema, FONTS } from "./customize";

const GUIDE = `You change the Tensai app for its owner by editing a JSON settings file.
Reply with ONLY a JSON object: {"summary": "<one or two plain sentences on what you changed>", "config": <the full new settings>}.
Keep everything the owner didn't ask to change exactly as it is.

Settings shape:
- appName?: string (max 30) — name shown in the sidebar.
- theme: { background?, foreground?, primary?, card? (all "#rrggbb"), displayFont?, bodyFont? (one of ${FONTS.join(", ")}), radius? (0-1.5, rem), dots? (boolean dot grid background) }
- buttons: [{ id, label, place: "sidebar"|"dashboard", action }]
  action is one of: {type:"workflow", workflowId, task} | {type:"agent", agentId, mode:"text"|"voice"} | {type:"link", url} | {type:"page", slug}
- pages: [{ id, slug (lowercase-with-dashes), title, inNav: boolean, blocks: [block] }]
  block: { id, type: "heading"|"text"|"buttons"|"app", text?, buttonIds? (for "buttons"), html? (for "app"), height? (100-2000 px) }

New features: when the owner asks for a tool, game, calculator, tracker, timer or any new feature, build it as a page with an "app" block containing a complete self-contained HTML document (inline CSS and JS, no external files). It runs in a sandbox: it may use localStorage-free in-memory state only, no network calls to the app. Style it to match the app: use the owner's theme colours if set, otherwise Tensai's defaults — background #090a13, text #f3f2f8, accent #7c4dff, panels #12121f — and set the document body background to match. Add the page to the sidebar (inNav true) unless told otherwise.
Use short random ids for new items. Only use workflow and agent ids from the lists provided.`;

export const editWithAI = createServerFn({ method: "POST" })
  .middleware([requireAppAuth])
  .inputValidator((d: { request: string; config: unknown }) => {
    if (!d.request?.trim() || d.request.length > 4000)
      throw new Error("Describe the change you want");
    return d;
  })
  .handler(async ({ data, context }) => {
    const db = context.supabase;
    const [{ data: agents }, { data: workflows }] = await Promise.all([
      db.from("agents").select("id, name"),
      db.from("workflows").select("id, name"),
    ]);
    const ai = resolveModel(await loadSettings(db, context.userId), "default", "medium");
    const prompt = `Agents: ${JSON.stringify(agents ?? [])}
Workflows: ${JSON.stringify(workflows ?? [])}
Current settings: ${JSON.stringify(data.config)}

Owner's request: ${data.request}`;
    let text: string;
    try {
      const r = await generateText({
        model: ai.model,
        instructions: GUIDE,
        prompt,
        maxRetries: 0,
        ...(ai.providerOptions ? { providerOptions: ai.providerOptions } : {}),
      } as Parameters<typeof generateText>[0]);
      text = r.text;
    } catch (e) {
      const msg = e instanceof Error ? e.message : "";
      const status = (e as { statusCode?: number }).statusCode;
      if (status === 402)
        throw new Error("Out of AI credits — top up or switch to a free AI in AI settings.");
      if (status === 429) throw new Error("The AI is busy right now — try again in a minute.");
      throw new Error(msg || "The AI couldn't make that change");
    }
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}");
    if (start < 0 || end < start)
      throw new Error("The AI didn't return a change. Try describing it differently.");
    let parsed: { summary?: unknown; config?: unknown };
    try {
      parsed = JSON.parse(text.slice(start, end + 1));
    } catch {
      throw new Error("The AI's change was incomplete. Try a smaller change.");
    }
    const cfg = configSchema.safeParse(parsed.config);
    if (!cfg.success) throw new Error("The AI's change didn't fit Tensai's settings. Try again.");
    return {
      summary: typeof parsed.summary === "string" ? parsed.summary : "Change ready.",
      config: cfg.data,
    };
  });
