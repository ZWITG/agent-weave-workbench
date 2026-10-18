import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import { Cloud, CloudOff, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type Status = {
  linked: boolean;
  email: string | null;
  pending: number;
  lastSync: string | null;
  lastError: string | null;
};

async function call(body?: unknown): Promise<Status> {
  const res = await fetch(
    "/api/local/sync",
    body
      ? {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        }
      : {},
  );
  const j = (await res.json()) as Status & { error?: string };
  if (!res.ok) throw new Error(j.error ?? "Sync failed");
  return j;
}

/** Desktop only: link the on-computer studio to the online account and keep both in step. */
export function DesktopSync() {
  const [s, setS] = useState<Status | null>(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  const refresh = useCallback(
    () =>
      void call()
        .then(setS)
        .catch(() => {}),
    [],
  );
  useEffect(() => {
    refresh();
    const t = setInterval(refresh, 10_000);
    return () => clearInterval(t);
  }, [refresh]);

  const run = async (body: unknown, ok: string) => {
    setBusy(true);
    try {
      const next = await call(body);
      setS(next);
      if (next.lastError) toast.error(next.lastError);
      else toast.success(ok);
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setBusy(false);
      setPassword("");
    }
  };

  return (
    <section className="mt-6 rounded-lg border border-border bg-card p-5">
      <h2 className="flex items-center gap-2 font-semibold">
        {s?.linked ? <Cloud className="h-4 w-4 text-primary" /> : <CloudOff className="h-4 w-4" />}{" "}
        Sync with your online account
      </h2>
      <p className="mt-1 text-sm text-muted-foreground">
        This app saves everything on your computer and works without internet. Link your online
        account to copy changes both ways whenever you're connected.
      </p>
      {s?.linked ? (
        <div className="mt-4 space-y-3 text-sm">
          <div>
            Linked to <span className="font-mono">{s.email}</span> ·{" "}
            {s.pending
              ? `${s.pending} change${s.pending === 1 ? "" : "s"} waiting`
              : "all changes copied"}
          </div>
          <div className="text-muted-foreground">
            {s.lastError ??
              (s.lastSync
                ? `Last synced ${new Date(s.lastSync).toLocaleString()}`
                : "Not synced yet")}
          </div>
          <div className="flex flex-wrap gap-2">
            <Button
              size="sm"
              onClick={() => void run({ action: "sync" }, "Synced")}
              disabled={busy}
            >
              <RefreshCw className={`h-4 w-4 ${busy ? "animate-spin" : ""}`} /> Sync now
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={() => void run({ action: "unlink" }, "Unlinked")}
              disabled={busy}
            >
              Unlink
            </Button>
          </div>
        </div>
      ) : (
        <form
          className="mt-4 grid gap-3"
          onSubmit={(e) => {
            e.preventDefault();
            void run({ action: "link", email, password }, "Linked and synced");
          }}
        >
          <div>
            <Label htmlFor="se">Email</Label>
            <Input
              id="se"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div>
            <Label htmlFor="sp">Password</Label>
            <Input
              id="sp"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <Button type="submit" className="w-fit" disabled={busy}>
            {busy ? "Linking…" : "Link account"}
          </Button>
        </form>
      )}
    </section>
  );
}
