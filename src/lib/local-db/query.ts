// A small Supabase-compatible query builder used by the desktop app's on-computer storage.
// It supports exactly the subset of the supabase-js API that Hive uses.

export type Row = Record<string, unknown>;
export type Filter =
  | { type: "eq"; col: string; val: unknown }
  | { type: "in"; col: string; val: unknown[] }
  | { type: "or"; expr: string };

export type Query = {
  table: string;
  op: "select" | "insert" | "update" | "upsert" | "delete";
  filters: Filter[];
  order: { col: string; asc: boolean }[];
  limit?: number;
  single?: "single" | "maybe";
  count?: boolean;
  head?: boolean;
  values?: Row | Row[];
  onConflict?: string;
  returning?: boolean;
};

export type Result = { data: unknown; error: { message: string } | null; count?: number | null };
export type Executor = (q: Query) => Promise<Result>;

class Builder implements PromiseLike<Result> {
  q: Query;
  constructor(
    private exec: Executor,
    table: string,
  ) {
    this.q = { table, op: "select", filters: [], order: [] };
  }
  select(_cols?: string, opts?: { count?: string; head?: boolean }) {
    if (this.q.op === "select") {
      if (opts?.count) this.q.count = true;
      if (opts?.head) this.q.head = true;
    } else this.q.returning = true;
    return this;
  }
  insert(values: Row | Row[]) {
    this.q.op = "insert";
    this.q.values = values;
    return this;
  }
  upsert(values: Row | Row[], opts?: { onConflict?: string }) {
    this.q.op = "upsert";
    this.q.values = values;
    if (opts?.onConflict) this.q.onConflict = opts.onConflict;
    return this;
  }
  update(values: Row) {
    this.q.op = "update";
    this.q.values = values;
    return this;
  }
  delete() {
    this.q.op = "delete";
    return this;
  }
  eq(col: string, val: unknown) {
    this.q.filters.push({ type: "eq", col, val });
    return this;
  }
  in(col: string, val: unknown[]) {
    this.q.filters.push({ type: "in", col, val });
    return this;
  }
  or(expr: string) {
    this.q.filters.push({ type: "or", expr });
    return this;
  }
  order(col: string, opts?: { ascending?: boolean }) {
    this.q.order.push({ col, asc: opts?.ascending ?? true });
    return this;
  }
  limit(n: number) {
    this.q.limit = n;
    return this;
  }
  single() {
    this.q.single = "single";
    return this;
  }
  maybeSingle() {
    this.q.single = "maybe";
    return this;
  }
  then<A = Result, B = never>(
    ok?: ((v: Result) => A | PromiseLike<A>) | null,
    fail?: ((e: unknown) => B | PromiseLike<B>) | null,
  ): PromiseLike<A | B> {
    return this.exec(this.q).then(ok, fail);
  }
}

export function makeFrom(exec: Executor) {
  return (table: string) => new Builder(exec, table);
}

const likeToRegex = (pattern: string) =>
  new RegExp(
    "^" +
      pattern
        .replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
        .replace(/%/g, ".*")
        .replace(/_/g, ".") +
      "$",
    "is",
  );

function matchOr(row: Row, expr: string) {
  return expr.split(",").some((part) => {
    const [col, op, ...rest] = part.split(".");
    const val = rest.join(".");
    const cell = String(row[col ?? ""] ?? "");
    if (op === "ilike") return likeToRegex(val).test(cell);
    if (op === "eq") return cell === val;
    return false;
  });
}

export function matches(row: Row, filters: Filter[]) {
  return filters.every((f) =>
    f.type === "eq"
      ? row[f.col] === f.val
      : f.type === "in"
        ? f.val.includes(row[f.col])
        : matchOr(row, f.expr),
  );
}

/** Applies ordering, limit and single/maybeSingle shaping to selected rows. */
export function shape(rows: Row[], q: Query): Result {
  let out = [...rows];
  for (const o of [...q.order].reverse()) {
    out.sort((a, b) => {
      const x = a[o.col] as string | number;
      const y = b[o.col] as string | number;
      const c = x < y ? -1 : x > y ? 1 : 0;
      return o.asc ? c : -c;
    });
  }
  const count = out.length;
  if (q.limit !== undefined) out = out.slice(0, q.limit);
  if (q.head) return { data: null, error: null, count };
  if (q.single) {
    if (out.length === 1) return { data: out[0], error: null };
    if (q.single === "maybe" && out.length === 0) return { data: null, error: null };
    return { data: null, error: { message: out.length ? "Multiple rows found" : "Row not found" } };
  }
  return { data: out, error: null, ...(q.count ? { count } : {}) };
}
