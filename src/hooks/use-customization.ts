import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";
import { db } from "@/lib/db";
import { parseConfig, themeVars, FONTS, type Config } from "@/lib/customize";

type Row = { id: string; config: unknown; history: unknown; updated_at: string };
const KEY = ["customization"];

async function fetchRow(): Promise<Row | null> {
  const { data } = await db
    .from("customizations")
    .select("id, config, history, updated_at")
    .order("updated_at", { ascending: false })
    .limit(1);
  return ((data ?? [])[0] as Row | undefined) ?? null;
}

export function useCustomization() {
  const qc = useQueryClient();
  const q = useQuery({ queryKey: KEY, queryFn: fetchRow });
  const row = q.data ?? null;
  const config = parseConfig(row?.config);
  const history = (Array.isArray(row?.history) ? row.history : []) as Config[];

  const write = async (next: Config, nextHistory: Config[]) => {
    const values = {
      config: next as never,
      history: nextHistory.slice(0, 20) as never,
      updated_at: new Date().toISOString(),
    };
    if (row) {
      const { error } = await db.from("customizations").update(values).eq("id", row.id);
      if (error) throw new Error(error.message);
    } else {
      const { data: u } = await db.auth.getUser();
      const { error } = await db
        .from("customizations")
        .insert({ ...values, user_id: u.user!.id });
      if (error) throw new Error(error.message);
    }
    await qc.invalidateQueries({ queryKey: KEY });
  };

  return {
    loading: q.isLoading,
    config,
    history,
    /** Saves a change; the previous version is kept so it can be undone. */
    save: (next: Config) => write(next, [config, ...history]),
    undo: () => (history[0] ? write(history[0], history.slice(1)) : Promise.resolve()),
  };
}

/** Applies the owner's colours and fonts to the whole app. */
export function useApplyTheme(config: Config) {
  const json = JSON.stringify(config.theme);
  useEffect(() => {
    const vars = themeVars(config.theme);
    const root = document.documentElement;
    for (const [k, v] of Object.entries(vars)) root.style.setProperty(k, v);
    const fonts = [config.theme.displayFont, config.theme.bodyFont].filter(
      (f): f is (typeof FONTS)[number] => !!f,
    );
    let link: HTMLLinkElement | null = null;
    if (fonts.length) {
      link = document.createElement("link");
      link.rel = "stylesheet";
      link.href = `https://fonts.googleapis.com/css2?${fonts
        .map((f) => `family=${f.replace(/ /g, "+")}:wght@400;700`)
        .join("&")}&display=swap`;
      document.head.appendChild(link);
    }
    return () => {
      for (const k of Object.keys(vars)) root.style.removeProperty(k);
      link?.remove();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [json]);
}
