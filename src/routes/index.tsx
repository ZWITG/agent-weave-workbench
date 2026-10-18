import { createFileRoute, Link } from "@tanstack/react-router";
import { Bot, Workflow, Brain, Activity } from "lucide-react";
import logo from "@/assets/tensai-logo.png.asset.json";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Tensai — Your private AI agent studio" },
      {
        name: "description",
        content: "Create AI agents, chain them into workflows, and watch them work together live.",
      },
      { property: "og:title", content: "Tensai — Your private AI agent studio" },
      {
        property: "og:description",
        content: "Create AI agents, chain them into workflows, and watch them work together live.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: Index,
});

function Index() {
  const features = [
    {
      icon: Bot,
      t: "Custom agents",
      d: "Roles, prompts and skills like web search or spawning helper AIs.",
    },
    {
      icon: Workflow,
      t: "Chained workflows",
      d: "Stages run in order; agents in a stage work side by side.",
    },
    { icon: Brain, t: "Shared mind", d: "What one agent learns, every agent can use." },
    {
      icon: Activity,
      t: "Live signal",
      d: "Watch every step, tool call and output as it happens.",
    },
  ];
  return (
    <main className="mx-auto flex min-h-screen max-w-5xl flex-col items-center justify-center px-6 py-16 text-center">
      <img
        src={logo.url}
        alt="Tensai logo"
        width={1920}
        height={1369}
        className="w-full max-w-md [mask-image:radial-gradient(ellipse_at_center,black_55%,transparent_80%)]"
      />
      <h1 className="mt-4 text-3xl leading-tight md:text-5xl">
        A TEAM OF AI AGENTS
        <br />
        <span className="text-primary">THINKING AS ONE</span>
      </h1>
      <p className="mt-6 max-w-xl text-lg text-muted-foreground">
        Design agents, connect them into workflows, and run them from one control room — online, or
        fully offline on your own computer.
      </p>
      <Link
        to="/auth"
        className="mt-8 inline-flex rounded-sm bg-primary px-8 py-3 font-mono text-sm font-semibold uppercase tracking-widest text-primary-foreground shadow-glow hover:bg-primary-glow"
      >
        Enter the studio
      </Link>
      <div className="mt-16 grid w-full gap-4 text-left md:grid-cols-4">
        {features.map((f) => (
          <div key={f.t} className="rounded-sm border border-dashed border-border bg-card/70 p-5">
            <f.icon className="h-5 w-5 text-primary" />
            <div className="mt-3 font-semibold">{f.t}</div>
            <p className="mt-1 text-sm text-muted-foreground">{f.d}</p>
          </div>
        ))}
      </div>
    </main>
  );
}
