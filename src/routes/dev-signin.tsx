import { createFileRoute } from "@tanstack/react-router";
import mark from "@/assets/tensai-mark.png.asset.json";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import "@lovable.dev/cloud-auth-js/styles.css";
import type { Session } from "@supabase/supabase-js";
import { supabase } from "@/integrations/supabase/client";
import { lovable } from "@/integrations/lovable/index";
import { Button } from "@/components/ui/button";
import { encodeDevSession, forgetStoredSession, isDevOrigin } from "@/lib/dev-signin";

export const Route = createFileRoute("/dev-signin")({
  head: () => ({
    meta: [
      { title: "Dev sign-in — Tensai" },
      { name: "description", content: "Sign in to a Tensai dev server on this computer." },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: DevSignin,
});

const KEY = "dev-signin-origin";

/** The target survives the Google round trip in sessionStorage; only loopback origins are accepted. */
function readOrigin() {
  const fromUrl = new URLSearchParams(window.location.search).get("origin");
  if (fromUrl) {
    try {
      sessionStorage.setItem(KEY, fromUrl);
    } catch {
      /* storage blocked: the URL value is still used for this load */
    }
  }
  let saved: string | null = null;
  try {
    saved = sessionStorage.getItem(KEY);
  } catch {
    /* ignore */
  }
  const origin = fromUrl ?? saved;
  return isDevOrigin(origin) ? origin : null;
}

function DevSignin() {
  const [origin, setOrigin] = useState<string | null | undefined>(undefined);
  const [session, setSession] = useState<Session | null | undefined>(undefined);

  useEffect(() => {
    setOrigin(readOrigin());
    void supabase.auth.getSession().then(({ data }) => setSession(data.session));
    const { data } = supabase.auth.onAuthStateChange((_event, next) => setSession(next));
    return () => data.subscription.unsubscribe();
  }, []);

  const google = async () => {
    const result = await lovable.auth.signInWithOAuth("google", {
      redirect_uri: window.location.origin + "/dev-signin",
    });
    if (result.error) toast.error(String(result.error.message ?? result.error));
  };

  const finish = () => {
    try {
      sessionStorage.removeItem(KEY);
    } catch {
      /* ignore */
    }
  };

  const allow = async () => {
    if (!origin || !session) return;
    const token = encodeDevSession({
      access_token: session.access_token,
      refresh_token: session.refresh_token,
    });
    // Only the dev server keeps this session: two clients rotating one refresh token would sign both out.
    // Not supabase.auth.signOut(): even with scope "local" it ends the session on the server, which is
    // the one being handed over.
    forgetStoredSession(localStorage);
    finish();
    window.location.replace(`${origin}/auth#dev_session=${token}`);
  };

  const cancel = () => {
    const target = origin;
    finish();
    window.location.replace(target ? `${target}/auth` : "/");
  };

  const loading = origin === undefined || session === undefined;

  return (
    <main className="flex min-h-screen items-center justify-center px-4">
      <div className="w-full max-w-sm rounded-xl border border-border bg-card p-8">
        <div className="flex items-center gap-3">
          <img
            src={mark.url}
            alt="Tensai"
            width={40}
            height={40}
            className="h-10 w-10 rounded-sm"
          />
          <span className="font-display text-2xl">TENSAI</span>
        </div>
        <h1 className="mt-4 text-2xl font-bold">Dev sign-in</h1>
        {loading ? (
          <p className="mt-3 text-sm text-muted-foreground">Loading…</p>
        ) : !origin ? (
          <p role="alert" className="mt-3 text-sm text-destructive">
            This page only signs in a dev server running on this computer (http://localhost or
            http://127.0.0.1). Open it from your dev server's sign-in page.
          </p>
        ) : !session ? (
          <div className="mt-4 space-y-3">
            <p className="text-sm text-muted-foreground">
              Sign in with Google here, then you can send that sign-in to {origin}.
            </p>
            <Button variant="secondary" className="w-full" onClick={() => void google()}>
              Continue with Google
            </Button>
            <Button variant="ghost" className="w-full" onClick={cancel}>
              Cancel
            </Button>
          </div>
        ) : (
          <div className="mt-4 space-y-3">
            <p className="text-sm text-muted-foreground">
              Sign in to the dev server at{" "}
              <span className="font-mono text-foreground">{origin}</span> as{" "}
              <span className="text-foreground">{session.user.email}</span>? You will be signed out
              of this page on this browser.
            </p>
            <Button className="w-full" onClick={() => void allow()}>
              Allow
            </Button>
            <Button variant="ghost" className="w-full" onClick={cancel}>
              Cancel
            </Button>
          </div>
        )}
      </div>
    </main>
  );
}
