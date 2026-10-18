import { createFileRoute } from "@tanstack/react-router";
import { rejectUntrusted } from "@/lib/local-db/guard.server";

// Live updates for the desktop app (replaces online realtime): Server-Sent Events.
export const Route = createFileRoute("/api/local/events")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const denied = rejectUntrusted(request);
        if (denied) return denied;
        const { events } = await import("@/lib/local-db/store.server");
        const enc = new TextEncoder();
        let cleanup = () => {};
        const stream = new ReadableStream({
          start(controller) {
            const send = (e: unknown) => controller.enqueue(enc.encode(`data: ${JSON.stringify(e)}\n\n`));
            const ping = setInterval(() => controller.enqueue(enc.encode(": ping\n\n")), 15000);
            events.on("change", send);
            cleanup = () => {
              clearInterval(ping);
              events.off("change", send);
            };
            request.signal.addEventListener("abort", () => {
              cleanup();
              try {
                controller.close();
              } catch {
                /* already closed */
              }
            });
          },
          cancel() {
            cleanup();
          },
        });
        return new Response(stream, {
          headers: { "Content-Type": "text/event-stream", "Cache-Control": "no-store", Connection: "keep-alive" },
        });
      },
    },
  },
});
