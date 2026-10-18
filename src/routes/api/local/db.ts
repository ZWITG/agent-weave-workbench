import { createFileRoute } from "@tanstack/react-router";
import type { Query } from "@/lib/local-db/query";
import { rejectUntrusted } from "@/lib/local-db/guard.server";

export const Route = createFileRoute("/api/local/db")({
  server: {
    handlers: {
      POST: async ({ request }) => {
        const denied = rejectUntrusted(request);
        if (denied) return denied;
        const { execute } = await import("@/lib/local-db/store.server");
        const q = (await request.json()) as Query;
        return Response.json(execute(q));
      },
    },
  },
});
