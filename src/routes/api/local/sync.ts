import { createFileRoute } from "@tanstack/react-router";
import { z } from "zod";
import { rejectUntrusted } from "@/lib/local-db/guard.server";

const body = z.discriminatedUnion("action", [
  z.object({ action: z.literal("link"), email: z.string().email(), password: z.string().min(1) }),
  z.object({ action: z.literal("sync") }),
  z.object({ action: z.literal("unlink") }),
]);

export const Route = createFileRoute("/api/local/sync")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const denied = rejectUntrusted(request);
        if (denied) return denied;
        const s = await import("@/lib/local-db/sync.server");
        s.startAutoSync();
        return Response.json(s.status());
      },
      POST: async ({ request }) => {
        const denied = rejectUntrusted(request);
        if (denied) return denied;
        const s = await import("@/lib/local-db/sync.server");
        try {
          const b = body.parse(await request.json());
          if (b.action === "link") return Response.json(await s.link(b.email, b.password));
          if (b.action === "unlink") return Response.json(s.unlink());
          return Response.json(await s.syncNow());
        } catch (e) {
          return Response.json({ error: e instanceof Error ? e.message : "Sync failed" }, { status: 400 });
        }
      },
    },
  },
});
