// Server-function auth that works both online (signed-in owner) and in the desktop app
// (on-computer studio, trusted by the window's per-launch secret header).
import { createMiddleware } from "@tanstack/react-start";
import { getRequest } from "@tanstack/react-start/server";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";

export const requireAppAuth = createMiddleware({ type: "function" }).server(async ({ next }) => {
  const request = getRequest();
  if (process.env["HIVE_LOCAL"] === "1") {
    const { isTrustedLocalRequest } = await import("./local-db/guard.server");
    if (!request || !isTrustedLocalRequest(request)) throw new Error("Unauthorized");
    const { localServerClient } = await import("./local-db/store.server");
    const { LOCAL_USER_ID } = await import("./local-db/constants");
    return next({
      context: {
        supabase: localServerClient() as unknown as SupabaseClient<Database>,
        userId: LOCAL_USER_ID,
      },
    });
  }
  const url = process.env["SUPABASE_URL"];
  const key = process.env["SUPABASE_PUBLISHABLE_KEY"];
  if (!url || !key) throw new Error("Sign-in service is not configured");
  const token = request?.headers.get("authorization")?.replace(/^Bearer /, "");
  if (!token || token.split(".").length !== 3) throw new Error("Unauthorized");
  const supabase = createClient<Database>(url, key, {
    global: {
      fetch: (input, init) => {
        const h = new Headers(init?.headers);
        if (h.get("Authorization") === `Bearer ${key}`) h.delete("Authorization");
        h.set("apikey", key);
        return fetch(input, { ...init, headers: h });
      },
      headers: { Authorization: `Bearer ${token}` },
    },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await supabase.auth.getClaims(token);
  if (error || !data?.claims?.sub) throw new Error("Unauthorized");
  return next({ context: { supabase, userId: data.claims.sub } });
});
