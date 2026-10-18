import { createFileRoute } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Plus, Trash2, Undo2, Sparkles, ArrowUp, ArrowDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Slider } from "@/components/ui/slider";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useCustomization, useApplyTheme } from "@/hooks/use-customization";
import { editWithAI } from "@/lib/customize.functions";
import {
  EMPTY_CONFIG,
  FONTS,
  newId,
  slugify,
  type Block,
  type ButtonAction,
  type Config,
  type CustomButton,
  type CustomPage,
} from "@/lib/customize";
import { useAgents } from "./agents";
import { useWorkflows } from "./workflows";
import { BlockView } from "./p.$slug";

export const Route = createFileRoute("/_authenticated/customize")({
  head: () => ({
    meta: [
      { title: "Customize — Tensai" },
      {
        name: "description",
        content: "Change Tensai's look, add buttons, pages and new features.",
      },
      { property: "og:title", content: "Customize — Tensai" },
      {
        property: "og:description",
        content: "Change Tensai's look, add buttons, pages and new features.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: Customize,
});

function Customize() {
  const { config, history, save, undo, loading } = useCustomization();
  const [draft, setDraft] = useState<Config>(config);
  const savedJson = JSON.stringify(config);
  useEffect(() => setDraft(JSON.parse(savedJson) as Config), [savedJson]);
  useApplyTheme(draft, config); // live preview while editing
  const dirty = JSON.stringify(draft) !== savedJson;

  const doSave = async (next: Config = draft) => {
    try {
      await save(next);
      toast.success("Saved — your changes are live everywhere");
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Couldn't save");
    }
  };
  if (loading) return null;

  return (
    <div>
      <div className="font-mono text-xs text-primary">MAKE IT YOURS</div>
      <div className="flex flex-wrap items-end justify-between gap-3">
        <h1 className="text-3xl">Customize</h1>
        <div className="flex gap-2">
          <Button
            variant="secondary"
            disabled={!history.length}
            onClick={() => void undo().then(() => toast.success("Undone"))}
          >
            <Undo2 className="h-4 w-4" /> Undo last change
          </Button>
          {dirty && (
            <Button variant="ghost" onClick={() => setDraft(config)}>
              Discard
            </Button>
          )}
          <Button disabled={!dirty} onClick={() => void doSave()}>
            Save changes
          </Button>
        </div>
      </div>
      <Tabs defaultValue="ai" className="mt-6">
        <TabsList className="flex-wrap">
          <TabsTrigger value="ai">Ask Tensai</TabsTrigger>
          <TabsTrigger value="look">Look</TabsTrigger>
          <TabsTrigger value="buttons">Buttons</TabsTrigger>
          <TabsTrigger value="pages">Pages</TabsTrigger>
        </TabsList>
        <TabsContent value="ai">
          <AskAI
            config={draft}
            onApply={(c) => {
              setDraft(c);
              void doSave(c);
            }}
          />
        </TabsContent>
        <TabsContent value="look">
          <LookEditor draft={draft} setDraft={setDraft} />
        </TabsContent>
        <TabsContent value="buttons">
          <ButtonsEditor draft={draft} setDraft={setDraft} />
        </TabsContent>
        <TabsContent value="pages">
          <PagesEditor draft={draft} setDraft={setDraft} />
        </TabsContent>
      </Tabs>
    </div>
  );
}

type EdProps = { draft: Config; setDraft: (c: Config) => void };
const card = "rounded-md border border-border bg-card p-5";

function AskAI({ config, onApply }: { config: Config; onApply: (c: Config) => void }) {
  const ask = useServerFn(editWithAI);
  const [text, setText] = useState("");
  const [busy, setBusy] = useState(false);
  const [proposal, setProposal] = useState<{ summary: string; config: Config } | null>(null);
  const go = async () => {
    setBusy(true);
    setProposal(null);
    try {
      setProposal(
        (await ask({ data: { request: text, config } })) as { summary: string; config: Config },
      );
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Couldn't make that change");
    } finally {
      setBusy(false);
    }
  };
  return (
    <div className={card}>
      <p className="text-sm text-muted-foreground">
        Describe a change in your own words — new colours, a button, a page, or a whole new feature
        like a timer, a notes board or a mini game. Uses the AI picked in AI settings.
      </p>
      <Textarea
        className="mt-3"
        rows={4}
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="e.g. Add a Pomodoro timer page to the sidebar, and make the accent colour green"
      />
      <Button className="mt-3" disabled={busy || !text.trim()} onClick={() => void go()}>
        <Sparkles className="h-4 w-4" /> {busy ? "Working on it…" : "Make this change"}
      </Button>
      {proposal && (
        <div className="mt-5 rounded-md border border-primary/50 p-4">
          <div className="font-semibold">Ready to apply</div>
          <p className="mt-1 text-sm text-muted-foreground">{proposal.summary}</p>
          <div className="mt-3 flex gap-2">
            <Button
              onClick={() => {
                onApply(proposal.config);
                setProposal(null);
                setText("");
              }}
            >
              Apply
            </Button>
            <Button variant="ghost" onClick={() => setProposal(null)}>
              Discard
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}

function ColorField({
  label,
  value,
  fallback,
  onChange,
}: {
  label: string;
  value?: string | undefined;
  fallback: string;
  onChange: (v?: string) => void;
}) {
  return (
    <div>
      <Label>{label}</Label>
      <div className="mt-1 flex items-center gap-2">
        <input
          type="color"
          aria-label={label}
          value={value ?? fallback}
          onChange={(e) => onChange(e.target.value)}
          className="h-9 w-12 cursor-pointer rounded border border-border bg-transparent"
        />
        <span className="font-mono text-xs text-muted-foreground">{value ?? "default"}</span>
        {value && (
          <Button size="sm" variant="ghost" onClick={() => onChange(undefined)}>
            Reset
          </Button>
        )}
      </div>
    </div>
  );
}

function FontField({
  label,
  value,
  onChange,
}: {
  label: string;
  value?: string | undefined;
  onChange: (v?: (typeof FONTS)[number]) => void;
}) {
  return (
    <div>
      <Label>{label}</Label>
      <Select
        value={value ?? "default"}
        onValueChange={(v) => onChange(v === "default" ? undefined : (v as (typeof FONTS)[number]))}
      >
        <SelectTrigger className="mt-1">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="default">Tensai default</SelectItem>
          {FONTS.map((f) => (
            <SelectItem key={f} value={f}>
              {f}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}

function LookEditor({ draft, setDraft }: EdProps) {
  const t = draft.theme;
  const set = (patch: Partial<Config["theme"]>) =>
    setDraft({ ...draft, theme: { ...t, ...patch } });
  return (
    <div className={`${card} grid gap-5 md:grid-cols-2`}>
      <div className="md:col-span-2">
        <Label htmlFor="app-name">App name in the sidebar</Label>
        <Input
          id="app-name"
          className="mt-1 max-w-sm"
          maxLength={30}
          value={draft.appName ?? ""}
          placeholder="Tensai"
          onChange={(e) => setDraft({ ...draft, appName: e.target.value || undefined })}
        />
      </div>
      <ColorField
        label="Background"
        value={t.background}
        fallback="#090a13"
        onChange={(v) => set({ background: v })}
      />
      <ColorField
        label="Text"
        value={t.foreground}
        fallback="#f3f2f8"
        onChange={(v) => set({ foreground: v })}
      />
      <ColorField
        label="Accent (buttons, highlights)"
        value={t.primary}
        fallback="#7c4dff"
        onChange={(v) => set({ primary: v })}
      />
      <ColorField
        label="Panels"
        value={t.card}
        fallback="#12121f"
        onChange={(v) => set({ card: v })}
      />
      <FontField
        label="Heading font"
        value={t.displayFont}
        onChange={(v) => set({ displayFont: v })}
      />
      <FontField label="Body font" value={t.bodyFont} onChange={(v) => set({ bodyFont: v })} />
      <div>
        <Label>Corner roundness</Label>
        <Slider
          className="mt-3"
          min={0}
          max={1.5}
          step={0.125}
          value={[t.radius ?? 0.25]}
          onValueChange={([v]) => set({ radius: v })}
        />
      </div>
      <div className="flex items-center gap-3">
        <Switch id="dots" checked={t.dots !== false} onCheckedChange={(v) => set({ dots: v })} />
        <Label htmlFor="dots">Dot grid background</Label>
      </div>
      <div className="md:col-span-2">
        <Button
          variant="ghost"
          onClick={() => setDraft({ ...draft, theme: EMPTY_CONFIG.theme, appName: undefined })}
        >
          Back to the original Tensai look
        </Button>
      </div>
    </div>
  );
}

function ActionFields({
  action,
  onChange,
  pages,
}: {
  action: ButtonAction;
  onChange: (a: ButtonAction) => void;
  pages: CustomPage[];
}) {
  const { data: agents = [] } = useAgents();
  const { data: workflows = [] } = useWorkflows();
  const setType = (type: ButtonAction["type"]) =>
    onChange(
      type === "workflow"
        ? { type, workflowId: workflows[0]?.id ?? "", task: "" }
        : type === "agent"
          ? { type, agentId: agents[0]?.id ?? "", mode: "text" }
          : type === "link"
            ? { type, url: "https://" }
            : { type, slug: pages[0]?.slug ?? "" },
    );
  return (
    <div className="grid gap-3 md:grid-cols-2">
      <div>
        <Label>What it does</Label>
        <Select value={action.type} onValueChange={(v) => setType(v as ButtonAction["type"])}>
          <SelectTrigger className="mt-1">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="workflow">Run a workflow</SelectItem>
            <SelectItem value="agent">Open an agent chat</SelectItem>
            <SelectItem value="link">Open a link</SelectItem>
            <SelectItem value="page">Open one of my pages</SelectItem>
          </SelectContent>
        </Select>
      </div>
      {action.type === "workflow" && (
        <>
          <div>
            <Label>Workflow</Label>
            <Select
              value={action.workflowId}
              onValueChange={(v) => onChange({ ...action, workflowId: v })}
            >
              <SelectTrigger className="mt-1">
                <SelectValue placeholder="Choose" />
              </SelectTrigger>
              <SelectContent>
                {workflows.map((w) => (
                  <SelectItem key={w.id} value={w.id}>
                    {w.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="md:col-span-2">
            <Label>Task to give it</Label>
            <Textarea
              className="mt-1"
              rows={2}
              value={action.task}
              onChange={(e) => onChange({ ...action, task: e.target.value })}
            />
          </div>
        </>
      )}
      {action.type === "agent" && (
        <>
          <div>
            <Label>Agent</Label>
            <Select
              value={action.agentId}
              onValueChange={(v) => onChange({ ...action, agentId: v })}
            >
              <SelectTrigger className="mt-1">
                <SelectValue placeholder="Choose" />
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
          <div>
            <Label>Start in</Label>
            <Select
              value={action.mode}
              onValueChange={(v) => onChange({ ...action, mode: v as "text" | "voice" })}
            >
              <SelectTrigger className="mt-1">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="text">Text</SelectItem>
                <SelectItem value="voice">Voice</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </>
      )}
      {action.type === "link" && (
        <div>
          <Label>Web address</Label>
          <Input
            className="mt-1"
            value={action.url}
            onChange={(e) => onChange({ ...action, url: e.target.value })}
          />
        </div>
      )}
      {action.type === "page" && (
        <div>
          <Label>Page</Label>
          <Select value={action.slug} onValueChange={(v) => onChange({ ...action, slug: v })}>
            <SelectTrigger className="mt-1">
              <SelectValue placeholder={pages.length ? "Choose" : "Make a page first"} />
            </SelectTrigger>
            <SelectContent>
              {pages.map((p) => (
                <SelectItem key={p.id} value={p.slug}>
                  {p.title}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      )}
    </div>
  );
}

function ButtonsEditor({ draft, setDraft }: EdProps) {
  const update = (i: number, b: CustomButton) =>
    setDraft({ ...draft, buttons: draft.buttons.map((x, j) => (j === i ? b : x)) });
  const add = () =>
    setDraft({
      ...draft,
      buttons: [
        ...draft.buttons,
        {
          id: newId(),
          label: "New button",
          place: "dashboard",
          action: { type: "link", url: "https://" },
        },
      ],
    });
  return (
    <div className="flex flex-col gap-4">
      {draft.buttons.map((b, i) => (
        <div key={b.id} className={`${card} flex flex-col gap-3`}>
          <div className="grid gap-3 md:grid-cols-[1fr_200px_auto]">
            <div>
              <Label>Button text</Label>
              <Input
                className="mt-1"
                maxLength={60}
                value={b.label}
                onChange={(e) => update(i, { ...b, label: e.target.value })}
              />
            </div>
            <div>
              <Label>Show it on</Label>
              <Select
                value={b.place}
                onValueChange={(v) => update(i, { ...b, place: v as CustomButton["place"] })}
              >
                <SelectTrigger className="mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="dashboard">Dashboard</SelectItem>
                  <SelectItem value="sidebar">Sidebar</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <Button
              variant="ghost"
              className="self-end"
              aria-label="Remove button"
              onClick={() =>
                setDraft({ ...draft, buttons: draft.buttons.filter((x) => x.id !== b.id) })
              }
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
          <ActionFields
            action={b.action}
            pages={draft.pages}
            onChange={(a) => update(i, { ...b, action: a })}
          />
        </div>
      ))}
      <Button variant="secondary" className="self-start" onClick={add}>
        <Plus className="h-4 w-4" /> Add a button
      </Button>
    </div>
  );
}

function PagesEditor({ draft, setDraft }: EdProps) {
  const [openId, setOpenId] = useState<string | null>(null);
  const update = (p: CustomPage) =>
    setDraft({ ...draft, pages: draft.pages.map((x) => (x.id === p.id ? p : x)) });
  const add = () => {
    const title = "New page";
    let slug = slugify(title);
    while (draft.pages.some((p) => p.slug === slug))
      slug = `${slugify(title)}-${newId().slice(0, 3)}`;
    const p: CustomPage = {
      id: newId(),
      slug,
      title,
      inNav: true,
      blocks: [{ id: newId(), type: "heading", text: "Hello" }],
    };
    setDraft({ ...draft, pages: [...draft.pages, p] });
    setOpenId(p.id);
  };
  return (
    <div className="flex flex-col gap-4">
      {draft.pages.map((p) => (
        <div key={p.id} className={card}>
          <div className="flex flex-wrap items-center gap-3">
            <div className="flex-1 font-semibold">{p.title}</div>
            <Button
              size="sm"
              variant="secondary"
              onClick={() => setOpenId(openId === p.id ? null : p.id)}
            >
              {openId === p.id ? "Close" : "Edit"}
            </Button>
            <Button
              size="sm"
              variant="ghost"
              aria-label="Remove page"
              onClick={() =>
                setDraft({ ...draft, pages: draft.pages.filter((x) => x.id !== p.id) })
              }
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
          {openId === p.id && <PageForm page={p} draft={draft} onChange={update} />}
        </div>
      ))}
      <Button variant="secondary" className="self-start" onClick={add}>
        <Plus className="h-4 w-4" /> Add a page
      </Button>
    </div>
  );
}

function PageForm({
  page,
  draft,
  onChange,
}: {
  page: CustomPage;
  draft: Config;
  onChange: (p: CustomPage) => void;
}) {
  const setBlock = (b: Block) =>
    onChange({ ...page, blocks: page.blocks.map((x) => (x.id === b.id ? b : x)) });
  const move = (i: number, d: number) => {
    const bl = [...page.blocks];
    const j = i + d;
    if (j < 0 || j >= bl.length) return;
    [bl[i], bl[j]] = [bl[j]!, bl[i]!];
    onChange({ ...page, blocks: bl });
  };
  const addBlock = (type: Block["type"]) =>
    onChange({
      ...page,
      blocks: [
        ...page.blocks,
        {
          id: newId(),
          type,
          ...(type === "app"
            ? {
                html: "<h1 style='font-family:sans-serif;color:white'>My feature</h1>",
                height: 400,
              }
            : type === "buttons"
              ? { buttonIds: [] }
              : { text: "" }),
        },
      ],
    });
  return (
    <div className="mt-4 flex flex-col gap-4">
      <div className="grid gap-3 md:grid-cols-[1fr_auto]">
        <div>
          <Label>Page title</Label>
          <Input
            className="mt-1"
            maxLength={60}
            value={page.title}
            onChange={(e) => onChange({ ...page, title: e.target.value })}
          />
        </div>
        <div className="flex items-center gap-2 self-end pb-2">
          <Switch
            id={`nav-${page.id}`}
            checked={page.inNav}
            onCheckedChange={(v) => onChange({ ...page, inNav: v })}
          />
          <Label htmlFor={`nav-${page.id}`}>Show in sidebar</Label>
        </div>
      </div>
      {page.blocks.map((b, i) => (
        <div key={b.id} className="rounded-md border border-dashed border-border p-3">
          <div className="mb-2 flex items-center gap-1">
            <span className="flex-1 font-mono text-xs uppercase text-muted-foreground">
              {b.type === "app" ? "feature (code)" : b.type}
            </span>
            <Button size="icon" variant="ghost" aria-label="Move up" onClick={() => move(i, -1)}>
              <ArrowUp className="h-4 w-4" />
            </Button>
            <Button size="icon" variant="ghost" aria-label="Move down" onClick={() => move(i, 1)}>
              <ArrowDown className="h-4 w-4" />
            </Button>
            <Button
              size="icon"
              variant="ghost"
              aria-label="Remove block"
              onClick={() =>
                onChange({ ...page, blocks: page.blocks.filter((x) => x.id !== b.id) })
              }
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
          {(b.type === "heading" || b.type === "text") &&
            (b.type === "heading" ? (
              <Input
                value={b.text ?? ""}
                onChange={(e) => setBlock({ ...b, text: e.target.value })}
              />
            ) : (
              <Textarea
                rows={3}
                value={b.text ?? ""}
                onChange={(e) => setBlock({ ...b, text: e.target.value })}
              />
            ))}
          {b.type === "buttons" && (
            <div className="flex flex-wrap gap-3">
              {draft.buttons.length === 0 && (
                <span className="text-sm text-muted-foreground">
                  Add buttons in the Buttons tab first.
                </span>
              )}
              {draft.buttons.map((btn) => (
                <label key={btn.id} className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={b.buttonIds?.includes(btn.id) ?? false}
                    onChange={(e) =>
                      setBlock({
                        ...b,
                        buttonIds: e.target.checked
                          ? [...(b.buttonIds ?? []), btn.id]
                          : (b.buttonIds ?? []).filter((x) => x !== btn.id),
                      })
                    }
                  />
                  {btn.label}
                </label>
              ))}
            </div>
          )}
          {b.type === "app" && (
            <div className="flex flex-col gap-2">
              <p className="text-xs text-muted-foreground">
                Paste HTML or ask Tensai to build it for you in the Ask Tensai tab. It runs safely
                in its own box.
              </p>
              <Textarea
                rows={8}
                className="font-mono text-xs"
                value={b.html ?? ""}
                onChange={(e) => setBlock({ ...b, html: e.target.value })}
              />
              <BlockView block={b} config={draft} />
            </div>
          )}
        </div>
      ))}
      <div className="flex flex-wrap gap-2">
        <Button size="sm" variant="secondary" onClick={() => addBlock("heading")}>
          <Plus className="h-4 w-4" /> Heading
        </Button>
        <Button size="sm" variant="secondary" onClick={() => addBlock("text")}>
          <Plus className="h-4 w-4" /> Text
        </Button>
        <Button size="sm" variant="secondary" onClick={() => addBlock("buttons")}>
          <Plus className="h-4 w-4" /> Buttons
        </Button>
        <Button size="sm" variant="secondary" onClick={() => addBlock("app")}>
          <Plus className="h-4 w-4" /> Feature (code)
        </Button>
      </div>
    </div>
  );
}
