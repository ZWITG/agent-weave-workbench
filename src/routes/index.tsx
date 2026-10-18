import { createFileRoute, Link } from "@tanstack/react-router";
import { Hexagon, Workflow, Brain, Activity } from "lucide-react";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Hive — Your private AI agent studio" },
      { name: "description", content: "Create AI agents, chain them into workflows, and watch them work together live." },
      { property: "og:title", content: "Hive — Your private AI agent studio" },
      { property: "og:description", content: "Create AI agents, chain them into workflows, and watch them work together live." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: Index,
});

function Index() {
  const features = [
    { icon: Hexagon, t: "Custom agents", d: "Roles, prompts and skills like web search or spawning helper AIs." },
    { icon: Workflow, t: "Chained workflows", d: "Stages run in order; agents in a stage work side by side." },
    { icon: Brain, t: "Shared knowledge", d: "What one agent learns, every agent can use." },
    { icon: Activity, t: "Live logs", d: "Watch every step, tool call and output as it happens." },
  ];
  return (
    <main className="mx-auto flex min-h-screen max-w-5xl flex-col justify-center px-6 py-16">
      <div className="flex items-center gap-2 font-mono text-sm text-primary">
        <Hexagon className="h-4 w-4" /> HIVE / PRIVATE STUDIO
      </div>
      <h1 className="mt-6 text-5xl font-bold leading-tight tracking-tight md:text-7xl">
        A team of AI agents,<br />
        <span className="text-primary">working as one.</span>
      </h1>
      <p className="mt-6 max-w-xl text-lg text-muted-foreground">
        Design agents, connect them into workflows, and run them from one control room.
      </p>
      <div className="mt-8">
        <Link to="/auth" className="inline-flex rounded-md bg-primary px-6 py-3 font-semibold text-primary-foreground hover:bg-primary/90">
          Enter the studio
        </Link>
      </div>
      <div className="mt-16 grid gap-4 md:grid-cols-4">
        {features.map((f) => (
          <div key={f.t} className="rounded-lg border border-border bg-card/70 p-5">
            <f.icon className="h-5 w-5 text-accent" />
            <div className="mt-3 font-semibold">{f.t}</div>
            <p className="mt-1 text-sm text-muted-foreground">{f.d}</p>
          </div>
        ))}
      </div>
    </main>
  );
}
