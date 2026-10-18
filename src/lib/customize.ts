// The owner's own changes to Tensai: look, extra buttons and extra pages. Browser-safe.
import { z } from "zod";

export const FONTS = [
  "Doto",
  "Sora",
  "Space Grotesk",
  "JetBrains Mono",
  "Silkscreen",
  "Press Start 2P",
  "VT323",
  "DM Sans",
  "Playfair Display",
  "Outfit",
] as const;

const hex = z.string().regex(/^#[0-9a-fA-F]{6}$/);
const id = z.string().min(1).max(64);

export const themeSchema = z.object({
  background: hex.optional(),
  foreground: hex.optional(),
  primary: hex.optional(),
  card: hex.optional(),
  displayFont: z.enum(FONTS).optional(),
  bodyFont: z.enum(FONTS).optional(),
  radius: z.number().min(0).max(1.5).optional(),
  dots: z.boolean().optional(),
});

export const actionSchema = z.discriminatedUnion("type", [
  z.object({ type: z.literal("workflow"), workflowId: z.string(), task: z.string().max(4000) }),
  z.object({ type: z.literal("agent"), agentId: z.string(), mode: z.enum(["text", "voice"]) }),
  z.object({ type: z.literal("link"), url: z.string().max(2000) }),
  z.object({ type: z.literal("page"), slug: z.string() }),
]);

export const buttonSchema = z.object({
  id,
  label: z.string().min(1).max(60),
  place: z.enum(["sidebar", "dashboard"]),
  action: actionSchema,
});

export const blockSchema = z.object({
  id,
  type: z.enum(["heading", "text", "buttons", "app"]),
  text: z.string().max(20000).optional(),
  buttonIds: z.array(z.string()).optional(),
  html: z.string().max(200000).optional(),
  height: z.number().min(100).max(2000).optional(),
});

export const pageSchema = z.object({
  id,
  slug: z.string().regex(/^[a-z0-9-]{1,40}$/),
  title: z.string().min(1).max(60),
  inNav: z.boolean(),
  blocks: z.array(blockSchema).max(50),
});

export const configSchema = z.object({
  appName: z.string().max(30).optional(),
  theme: themeSchema.default({}),
  buttons: z.array(buttonSchema).max(50).default([]),
  pages: z.array(pageSchema).max(30).default([]),
});

export type Theme = z.infer<typeof themeSchema>;
export type ButtonAction = z.infer<typeof actionSchema>;
export type CustomButton = z.infer<typeof buttonSchema>;
export type Block = z.infer<typeof blockSchema>;
export type CustomPage = z.infer<typeof pageSchema>;
export type Config = z.infer<typeof configSchema>;

export const EMPTY_CONFIG: Config = { theme: {}, buttons: [], pages: [] };

/** Reads a stored config, dropping anything broken instead of crashing the app. */
export function parseConfig(raw: unknown): Config {
  const r = configSchema.safeParse(raw ?? {});
  return r.success ? r.data : EMPTY_CONFIG;
}

export const newId = () => Math.random().toString(36).slice(2, 10);

export const slugify = (s: string) =>
  s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 40) || "page";

/** CSS variables to set on the page for a theme. Unset values keep Tensai's defaults. */
export function themeVars(t: Theme): Record<string, string> {
  const v: Record<string, string> = {};
  if (t.background) {
    v["--background"] = t.background;
    v["--sidebar"] = `color-mix(in oklab, ${t.background} 90%, black)`;
    v["--secondary"] = `color-mix(in oklab, ${t.background} 85%, white)`;
    v["--muted"] = `color-mix(in oklab, ${t.background} 88%, white)`;
    v["--sidebar-accent"] = `color-mix(in oklab, ${t.background} 85%, white)`;
    v["--border"] = `color-mix(in oklab, ${t.background} 78%, white)`;
    v["--sidebar-border"] = `color-mix(in oklab, ${t.background} 80%, white)`;
    v["--input"] = `color-mix(in oklab, ${t.background} 75%, white)`;
    if (!t.card) v["--card"] = `color-mix(in oklab, ${t.background} 93%, white)`;
    v["--popover"] = `color-mix(in oklab, ${t.background} 92%, white)`;
  }
  if (t.card) v["--card"] = t.card;
  if (t.foreground) {
    for (const k of ["--foreground", "--card-foreground", "--popover-foreground", "--secondary-foreground", "--sidebar-foreground", "--sidebar-accent-foreground"])
      v[k] = t.foreground;
    v["--muted-foreground"] = `color-mix(in oklab, ${t.foreground} 65%, transparent)`;
    v["--dot"] = `color-mix(in oklab, ${t.foreground} 7%, transparent)`;
  }
  if (t.primary) {
    for (const k of ["--primary", "--ring", "--sidebar-primary", "--sidebar-ring", "--chart-1"]) v[k] = t.primary;
    v["--primary-glow"] = `color-mix(in oklab, ${t.primary} 75%, white)`;
    v["--accent"] = `color-mix(in oklab, ${t.primary} 60%, black)`;
  }
  if (t.displayFont) v["--font-display"] = `"${t.displayFont}", monospace`;
  if (t.bodyFont) v["--font-sans"] = `"${t.bodyFont}", sans-serif`;
  if (t.radius !== undefined) v["--radius"] = `${t.radius}rem`;
  if (t.dots === false) v["--dot"] = "transparent";
  return v;
}
