import { createFileRoute, Link, Outlet, redirect, useNavigate } from "@tanstack/react-router";
import { useQueryClient } from "@tanstack/react-query";
import {
  LayoutDashboard,
  Bot,
  Workflow,
  Brain,
  LogOut,
  Lock,
  Settings,
  Paintbrush,
  FileText,
} from "lucide-react";
import { db as supabase } from "@/lib/db";
import { Button } from "@/components/ui/button";
import mark from "@/assets/tensai-mark.png.asset.json";
import { isDesktop } from "@/lib/ai-settings";
import { useEffect, useState } from "react";
import { useApplyTheme, useCustomization } from "@/hooks/use-customization";
import { CustomButtonView } from "@/components/custom-button";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async () => {
    const { data } = await supabase.auth.getUser();
    if (!data.user) throw redirect({ to: "/auth" });
    const { data: isOwner } = await supabase.rpc("claim_owner");
    return { user: data.user, isOwner: !!isOwner };
  },
  component: Layout,
});

const nav = [
  { to: "/dashboard", label: "Control room", icon: LayoutDashboard },
  { to: "/agents", label: "Agents", icon: Bot },
  { to: "/workflows", label: "Workflows", icon: Workflow },
  { to: "/knowledge", label: "Knowledge", icon: Brain },
  { to: "/settings", label: "AI settings", icon: Settings },
  { to: "/customize", label: "Customize", icon: Paintbrush },
] as const;

function Layout() {
  const { isOwner, user } = Route.useRouteContext();
  const qc = useQueryClient();
  const navigate = useNavigate();
  const [desktop, setDesktop] = useState(false);
  useEffect(() => setDesktop(isDesktop()), []);
  const { config } = useCustomization();
  useApplyTheme(config);
  const navPages = config.pages.filter((p) => p.inNav);
  const sideButtons = config.buttons.filter((b) => b.place === "sidebar");
  const signOut = async () => {
    await qc.cancelQueries();
    qc.clear();
    await supabase.auth.signOut();
    navigate({ to: "/auth", replace: true });
  };

  if (!isOwner) {
    return (
      <main className="flex min-h-screen items-center justify-center px-4">
        <div className="max-w-sm rounded-xl border border-border bg-card p-8 text-center">
          <Lock className="mx-auto h-6 w-6 text-primary" />
          <h1 className="mt-3 text-xl font-bold">Private studio</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            This studio belongs to another account. {user.email} has no access.
          </p>
          <Button className="mt-5" variant="secondary" onClick={signOut}>
            Sign out
          </Button>
        </div>
      </main>
    );
  }

  return (
    <div className="flex min-h-screen">
      <aside className="sticky top-0 hidden h-screen w-56 flex-col border-r border-sidebar-border bg-sidebar p-4 md:flex">
        <div className="flex items-center gap-3 px-2">
          <img src={mark.url} alt="Tensai" width={32} height={32} className="h-8 w-8 rounded-sm" />
          <span className="truncate font-display text-xl">
            {(config.appName || "Tensai").toUpperCase()}
          </span>
          {!config.appName && <span className="font-mono text-xs text-primary">天才</span>}
        </div>
        <nav className="mt-8 flex flex-1 flex-col gap-1">
          {nav.map((n) => (
            <Link
              key={n.to}
              to={n.to}
              className="flex items-center gap-3 rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-sidebar-accent hover:text-foreground"
              activeProps={{ className: "bg-sidebar-accent !text-foreground" }}
            >
              <n.icon className="h-4 w-4" /> {n.label}
            </Link>
          ))}
          {navPages.map((p) => (
            <Link
              key={p.id}
              to="/p/$slug"
              params={{ slug: p.slug }}
              className="flex items-center gap-3 rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-sidebar-accent hover:text-foreground"
              activeProps={{ className: "bg-sidebar-accent !text-foreground" }}
            >
              <FileText className="h-4 w-4" /> <span className="truncate">{p.title}</span>
            </Link>
          ))}
          {sideButtons.length > 0 && (
            <div className="mt-4 flex flex-col gap-2 border-t border-sidebar-border pt-4">
              {sideButtons.map((b) => (
                <CustomButtonView key={b.id} button={b} className="justify-start" />
              ))}
            </div>
          )}
        </nav>
        <div className="truncate px-2 font-mono text-xs text-muted-foreground">{user.email}</div>
        {!desktop && (
          <button
            onClick={signOut}
            className="mt-2 flex items-center gap-2 rounded-md px-3 py-2 text-sm text-muted-foreground hover:text-foreground"
          >
            <LogOut className="h-4 w-4" /> Sign out
          </button>
        )}
      </aside>
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap gap-1 border-b border-border p-2 md:hidden">
          {nav.map((n) => (
            <Link
              key={n.to}
              to={n.to}
              className="whitespace-nowrap rounded-md px-3 py-1.5 text-sm text-muted-foreground"
              activeProps={{ className: "bg-secondary !text-foreground" }}
            >
              {n.label}
            </Link>
          ))}
          {navPages.map((p) => (
            <Link
              key={p.id}
              to="/p/$slug"
              params={{ slug: p.slug }}
              className="whitespace-nowrap rounded-md px-3 py-1.5 text-sm text-muted-foreground"
              activeProps={{ className: "bg-secondary !text-foreground" }}
            >
              {p.title}
            </Link>
          ))}
        </div>
        <main className="mx-auto max-w-6xl p-6 md:p-10">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
