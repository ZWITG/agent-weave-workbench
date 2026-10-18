// The app's data client. On the website it is the online account; inside the desktop app
// it is the on-computer studio (same API, stored locally, works with no internet).
import { supabase } from "@/integrations/supabase/client";
import { LOCAL_USER_ID } from "./local-db/constants";
import { makeFrom, matches, type Row } from "./local-db/query";
import { isDesktop } from "./ai-settings";

type Listener = { table: string; event: string; filter?: string; cb: (p: unknown) => void };

function createLocalClient() {
  let source: EventSource | null = null;
  const listeners = new Set<Listener>();
  const ensureSource = () => {
    if (source) return;
    source = new EventSource("/api/local/events");
    source.onmessage = (m) => {
      const e = JSON.parse(m.data as string) as { table: string; eventType: string; new: Row; old: Row };
      for (const l of listeners) {
        if (l.table !== e.table || (l.event !== "*" && l.event !== e.eventType)) continue;
        if (l.filter) {
          const [col, rest] = l.filter.split("=");
          const val = rest?.replace(/^eq\./, "");
          const row = e.eventType === "DELETE" ? e.old : e.new;
          if (!matches({ v: String(row[col ?? ""] ?? "") }, [{ type: "eq", col: "v", val }])) continue;
        }
        l.cb(e);
      }
    };
  };
  const user = { id: LOCAL_USER_ID, email: "This computer" };
  return {
    from: makeFrom(async (q) => {
      const res = await fetch("/api/local/db", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(q),
      });
      if (!res.ok) return { data: null, error: { message: `Local storage error (${res.status})` } };
      return res.json();
    }),
    rpc: async () => ({ data: true, error: null }),
    channel: (_name: string) => {
      const mine: Listener[] = [];
      const ch = {
        on: (_type: string, opts: { event: string; table: string; filter?: string }, cb: (p: unknown) => void) => {
          mine.push({ table: opts.table, event: opts.event, cb, ...(opts.filter ? { filter: opts.filter } : {}) });
          return ch;
        },
        subscribe: () => {
          ensureSource();
          mine.forEach((l) => listeners.add(l));
          return ch;
        },
        unsubscribe: () => mine.forEach((l) => listeners.delete(l)),
      };
      return ch;
    },
    removeChannel: (ch: { unsubscribe: () => void }) => {
      ch.unsubscribe();
      return Promise.resolve("ok");
    },
    auth: {
      getUser: async () => ({ data: { user }, error: null }),
      getSession: async () => ({ data: { session: null }, error: null }),
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe() {} } } }),
      signOut: async () => ({ error: null }),
    },
  };
}

let local: ReturnType<typeof createLocalClient> | null = null;
const pick = () => (isDesktop() ? (local ??= createLocalClient()) : supabase);

export const db = new Proxy({} as typeof supabase, {
  get: (_t, k) => {
    const target = pick() as unknown as Record<string | symbol, unknown>;
    const v = target[k];
    return typeof v === "function" ? (v as (...a: unknown[]) => unknown).bind(target) : v;
  },
});
