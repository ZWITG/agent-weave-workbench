import { createFileRoute, Link } from "@tanstack/react-router";
import { ArrowLeft } from "lucide-react";
import { useAgents } from "./agents";
import { AgentConversation } from "@/components/agent-conversation";
import { useDeviceConversations } from "@/lib/conversation-store";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/_authenticated/agents_/$agentId")({
  validateSearch: (search: Record<string, unknown>) => ({
    mode: search["mode"] === "voice" ? ("voice" as const) : ("text" as const),
  }),
  head: () => ({
    meta: [
      { title: "Agent conversation — Hive" },
      { name: "description", content: "Speak privately with your Hive agents by text or voice." },
      { property: "og:title", content: "Agent conversation — Hive" },
      {
        property: "og:description",
        content: "Speak privately with your Hive agents by text or voice.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: AgentPage,
});
function AgentPage() {
  const { agentId } = Route.useParams();
  const { mode } = Route.useSearch();
  const { user } = Route.useRouteContext();
  const { data: agents = [], isPending } = useAgents();
  const device = useDeviceConversations(user.id);
  const agent = agents.find((a) => a.id === agentId);
  return (
    <div className="min-w-0">
      <Button asChild variant="ghost" size="sm" className="mb-5">
        <Link to="/agents">
          <ArrowLeft /> Agents
        </Link>
      </Button>
      {!device.ready || isPending ? (
        <p className="text-muted-foreground">Loading conversation…</p>
      ) : agent ? (
        <AgentConversation
          key={`${user.id}:${agentId}`}
          agent={agent}
          agents={agents}
          userId={user.id}
          saved={device.records[agentId]}
          initialMode={mode}
        />
      ) : (
        <p role="alert">Agent not found.</p>
      )}
    </div>
  );
}
