import { createFileRoute, Link } from "@tanstack/react-router";
import { useCustomization } from "@/hooks/use-customization";
import { CustomButtonView } from "@/components/custom-button";
import type { Block, Config } from "@/lib/customize";

export const Route = createFileRoute("/_authenticated/p/$slug")({
  head: () => ({
    meta: [
      { title: "Your page — Tensai" },
      { name: "description", content: "A page you added to your Tensai studio." },
      { property: "og:title", content: "Your page — Tensai" },
      { property: "og:description", content: "A page you added to your Tensai studio." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: CustomPageRoute,
});

export function BlockView({ block, config }: { block: Block; config: Config }) {
  if (block.type === "heading") return <h2 className="font-display text-2xl">{block.text}</h2>;
  if (block.type === "text")
    return <p className="whitespace-pre-wrap text-muted-foreground">{block.text}</p>;
  if (block.type === "buttons") {
    const btns = config.buttons.filter((b) => block.buttonIds?.includes(b.id));
    return (
      <div className="flex flex-wrap gap-2">
        {btns.map((b) => (
          <CustomButtonView key={b.id} button={b} variant="default" />
        ))}
        {!btns.length && (
          <span className="text-sm text-muted-foreground">No buttons chosen yet.</span>
        )}
      </div>
    );
  }
  return (
    <iframe
      title="Feature"
      srcDoc={block.html ?? ""}
      sandbox="allow-scripts allow-forms allow-modals"
      style={{ height: block.height ?? 500 }}
      className="w-full rounded-md border border-border bg-card"
    />
  );
}

function CustomPageRoute() {
  const { slug } = Route.useParams();
  const { config, loading } = useCustomization();
  const page = config.pages.find((p) => p.slug === slug);
  if (loading) return null;
  if (!page)
    return (
      <div>
        <h1 className="text-2xl">Page not found</h1>
        <Link to="/customize" className="mt-3 inline-block text-primary underline">
          Open Customize
        </Link>
      </div>
    );
  return (
    <div className="flex flex-col gap-5">
      <h1 className="text-3xl">{page.title}</h1>
      {page.blocks.map((b) => (
        <BlockView key={b.id} block={b} config={config} />
      ))}
    </div>
  );
}
