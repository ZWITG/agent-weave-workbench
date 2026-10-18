// Copies the desktop app's on-computer studio to and from the online account when internet is available.
// Local edits are pushed first (they win), then the online copy is pulled in.
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";
import { LOCAL_USER_ID, SYNC_TABLES } from "./constants";
import { load, save, events, type Change } from "./store.server";
import type { Row } from "./query";

type Db = SupabaseClient<Database>;
let running: Promise<SyncStatus> | null = null;

export type SyncStatus = {
  linked: boolean;
  email: string | null;
  pending: number;
  lastSync: string | null;
  lastError: string | null;
};

export function status(): SyncStatus {
  const m = load().meta;
  return {
    linked: !!m.link,
    email: m.link?.email ?? null,
    pending: m.dirty.length,
    lastSync: m.lastSync,
    lastError: m.lastError,
  };
}

function client(): Db {
  const url = process.env["SUPABASE_URL"];
  const key = process.env["SUPABASE_PUBLISHABLE_KEY"];
  if (!url || !key) throw new Error("Online account settings are missing");
  return createClient<Database>(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
}

export async function link(email: string, password: string) {
  const db = client();
  const { data, error } = await db.auth.signInWithPassword({ email, password });
  if (error || !data.session) throw new Error(error?.message ?? "Could not sign in");
  const { data: owner } = await db.rpc("claim_owner");
  if (!owner) throw new Error("This account doesn't own the online studio");
  const m = load().meta;
  m.link = { refresh_token: data.session.refresh_token, user_id: data.user.id, email: email };
  // Everything already on this computer should be copied up on first sync.
  for (const t of SYNC_TABLES) {
    for (const r of load().tables[t]!) {
      if (!m.dirty.some((c) => c.table === t && c.id === r["id"]))
        m.dirty.push({ table: t, id: r["id"] as string, op: "upsert" });
    }
  }
  save(true);
  return syncNow();
}

export function unlink() {
  const m = load().meta;
  m.link = null;
  m.synced = {};
  save(true);
  return status();
}

const toRemote = (row: Row, uid: string) => ({ ...row, user_id: uid });
const toLocal = (row: Row) => ({ ...row, user_id: LOCAL_USER_ID });

async function push(db: Db, uid: string) {
  const d = load();
  const m = d.meta;
  const order = (c: Change) =>
    c.op === "delete" ? 100 - SYNC_TABLES.indexOf(c.table as never) : SYNC_TABLES.indexOf(c.table as never);
  const queue = [...m.dirty].sort((a, b) => order(a) - order(b));
  for (const c of queue) {
    const table = c.table as (typeof SYNC_TABLES)[number];
    const t = db.from(table as "agents");
    if (c.op === "delete") {
      if (!(table === "run_logs" && Number(c.id) < 0)) {
        const { error } = await t.delete().eq("id", c.id as string);
        if (error) throw new Error(error.message);
      }
    } else {
      const row = d.tables[table]!.find((r) => r["id"] === c.id);
      if (row) {
        if (table === "run_logs" && Number(row["id"]) < 0) {
          // Log lines get their number from the online account.
          const { id: _drop, ...rest } = row;
          const { data, error } = await db
            .from("run_logs")
            .insert(toRemote(rest, uid) as never)
            .select("id")
            .single();
          if (error) throw new Error(error.message);
          row["id"] = data.id;
        } else {
          const { error } = await t.upsert(toRemote(row, uid) as never);
          if (error) throw new Error(error.message);
        }
      }
    }
    m.dirty = m.dirty.filter((x) => x !== c);
    save();
  }
}

async function pull(db: Db) {
  const d = load();
  const m = d.meta;
  for (const table of SYNC_TABLES) {
    const { data, error } = await db.from(table as "agents").select("*");
    if (error) throw new Error(error.message);
    const remote = (data ?? []) as unknown as Row[];
    const dirtyIds = new Set(m.dirty.filter((c) => c.table === table).map((c) => c.id));
    const rows = d.tables[table]!;
    const remoteIds = new Set(remote.map((r) => r["id"] as string | number));
    const previouslySynced = new Set(m.synced[table] ?? []);
    // Removed online (and not changed here since) → remove here too.
    d.tables[table] = rows.filter(
      (r) => remoteIds.has(r["id"] as string) || dirtyIds.has(r["id"] as string) || !previouslySynced.has(r["id"] as string),
    );
    for (const r of remote) {
      if (dirtyIds.has(r["id"] as string)) continue;
      const existing = d.tables[table]!.find((x) => x["id"] === r["id"]);
      if (existing) Object.assign(existing, toLocal(r));
      else d.tables[table]!.push(toLocal(r));
    }
    m.synced[table] = [...remoteIds];
    events.emit("change", { table, eventType: "UPDATE", new: {}, old: {} });
  }
}

export function syncNow(): Promise<SyncStatus> {
  if (running) return running;
  running = (async () => {
    const m = load().meta;
    if (!m.link) return status();
    try {
      const db = client();
      const { data, error } = await db.auth.refreshSession({ refresh_token: m.link.refresh_token });
      if (error || !data.session) throw new Error(error?.message ?? "Please link your online account again");
      m.link.refresh_token = data.session.refresh_token;
      save(true);
      await push(db, m.link.user_id);
      await pull(db);
      m.lastSync = new Date().toISOString();
      m.lastError = null;
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Sync failed";
      m.lastError = /fetch failed|ENOTFOUND|ECONNREFUSED|network/i.test(msg) ? "Offline — will sync when internet is back" : msg;
    } finally {
      save(true);
      running = null;
    }
    return status();
  })();
  return running;
}

let timer: ReturnType<typeof setInterval> | null = null;
/** Background sync every minute while the desktop app is open. */
export function startAutoSync() {
  if (timer) return;
  timer = setInterval(() => void syncNow(), 60_000);
  setTimeout(() => void syncNow(), 3_000);
}
