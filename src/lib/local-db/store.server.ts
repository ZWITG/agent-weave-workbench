// On-computer storage for the desktop app: one JSON file in the app's data folder.
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { EventEmitter } from "node:events";
import { LOCAL_TABLES, LOCAL_USER_ID, SYNC_TABLES } from "./constants";
import { makeFrom, matches, shape, type Query, type Result, type Row } from "./query";

export type Change = { table: string; id: string | number; op: "upsert" | "delete" };
export type SyncLink = { refresh_token: string; user_id: string; email: string };
type Data = {
  tables: Record<string, Row[]>;
  meta: {
    nextLogId: number;
    dirty: Change[];
    synced: Record<string, (string | number)[]>;
    link: SyncLink | null;
    lastSync: string | null;
    lastError: string | null;
  };
};

export const events = new EventEmitter();
events.setMaxListeners(100);

let data: Data | null = null;
let saveTimer: ReturnType<typeof setTimeout> | null = null;

function file() {
  const dir = process.env["HIVE_DATA_DIR"] || join(process.cwd(), "hive-data");
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  return join(dir, "hive-data.json");
}

export function load(): Data {
  if (data) return data;
  const f = file();
  data = existsSync(f)
    ? (JSON.parse(readFileSync(f, "utf8")) as Data)
    : {
        tables: {},
        meta: { nextLogId: -1, dirty: [], synced: {}, link: null, lastSync: null, lastError: null },
      };
  for (const t of LOCAL_TABLES) data.tables[t] ??= [];
  if (!data.tables["ai_settings"]!.length) {
    data.tables["ai_settings"]!.push({
      user_id: LOCAL_USER_ID,
      default_provider: "ollama",
      ollama_url: "http://127.0.0.1:11434",
      ollama_model: "qwen2.5:7b",
      custom_base_url: "https://api.openai.com/v1",
      custom_api_key: "",
      custom_model: "gpt-4o-mini",
      updated_at: new Date().toISOString(),
    });
  }
  return data;
}

export function save(now = false) {
  const write = () => {
    saveTimer = null;
    const f = file();
    writeFileSync(f + ".tmp", JSON.stringify(data));
    renameSync(f + ".tmp", f);
  };
  if (now) return write();
  if (!saveTimer) saveTimer = setTimeout(write, 250);
}

const keyOf = (table: string) => (table === "ai_settings" ? "user_id" : "id");

function defaults(table: string, row: Row): Row {
  const d = load();
  const now = new Date().toISOString();
  const base: Row = { user_id: LOCAL_USER_ID, ...row };
  if (table === "run_logs")
    base["id"] ??= d.meta.nextLogId--; // negative = not yet synced
  else if (table !== "ai_settings") base["id"] ??= crypto.randomUUID();
  if (table === "runs") {
    base["started_at"] ??= now;
    base["status"] ??= "running";
    base["output"] ??= null;
    base["mode"] ??= "run";
    base["plan"] ??= null;
    base["finished_at"] ??= null;
  } else if (table !== "ai_settings") base["created_at"] ??= now;
  if (table === "artifacts") base["updated_at"] ??= now;
  if (table === "agents") {
    base["role"] ??= "";
    base["system_prompt"] ??= "";
    base["skills"] ??= [];
    base["color"] ??= "amber";
    base["provider"] ??= "default";
  }
  if (table === "workflows") {
    base["description"] ??= "";
    base["stages"] ??= [];
  }
  return base;
}

function markDirty(table: string, id: string | number, op: Change["op"]) {
  if (!(SYNC_TABLES as readonly string[]).includes(table)) return;
  const m = load().meta;
  m.dirty = m.dirty.filter((c) => !(c.table === table && c.id === id));
  m.dirty.push({ table, id, op });
}

function emit(table: string, eventType: "INSERT" | "UPDATE" | "DELETE", row: Row, old?: Row) {
  events.emit("change", {
    table,
    eventType,
    new: eventType === "DELETE" ? {} : row,
    old: old ?? {},
  });
}

/** Runs one query against the local data. `track` = record the change for syncing. */
export function execute(q: Query, track = true): Result {
  const d = load();
  const rows = d.tables[q.table];
  if (!rows) return { data: null, error: { message: `Unknown table ${q.table}` } };
  const key = keyOf(q.table);
  if (q.op === "select")
    return shape(
      rows.filter((r) => matches(r, q.filters)),
      q,
    );

  const touched: Row[] = [];
  if (q.op === "insert" || q.op === "upsert") {
    const list = Array.isArray(q.values) ? q.values : [q.values ?? {}];
    const conflict = q.onConflict?.split(",") ?? [key];
    for (const v of list) {
      const existing =
        q.op === "upsert" ? rows.find((r) => conflict.every((c) => r[c] === v[c])) : undefined;
      if (existing) {
        const old = { ...existing };
        Object.assign(existing, v);
        touched.push(existing);
        emit(q.table, "UPDATE", existing, old);
      } else {
        const row = defaults(q.table, v);
        rows.push(row);
        touched.push(row);
        emit(q.table, "INSERT", row);
      }
    }
  } else if (q.op === "update") {
    for (const r of rows.filter((r) => matches(r, q.filters))) {
      const old = { ...r };
      Object.assign(r, q.values);
      touched.push(r);
      emit(q.table, "UPDATE", r, old);
    }
  } else if (q.op === "delete") {
    const gone = rows.filter((r) => matches(r, q.filters));
    d.tables[q.table] = rows.filter((r) => !gone.includes(r));
    for (const r of gone) {
      if (track) markDirty(q.table, r[key] as string, "delete");
      emit(q.table, "DELETE", r, r);
    }
    save();
    return { data: q.returning ? gone : null, error: null };
  }
  if (track) for (const r of touched) markDirty(q.table, r[key] as string, "upsert");
  save();
  if (!q.returning) return { data: null, error: null };
  return shape(touched, { ...q, order: [], filters: [] });
}

/** A supabase-js–shaped client over the local data, for server code (engine, chat). */
export function localServerClient() {
  return {
    from: makeFrom(async (q) => execute(q)),
    rpc: async () => ({ data: true, error: null }),
    auth: {
      getUser: async () => ({
        data: { user: { id: LOCAL_USER_ID, email: "this computer" } },
        error: null,
      }),
    },
  };
}
