import { useEffect, useState } from "react";
import { Download, MonitorDown } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { installerLinks, type InstallerLinks } from "@/lib/installers";

type InstallEvent = Event & { prompt(): Promise<void>; userChoice: Promise<{ outcome: string }> };

export function GetApp() {
  const [prompt, setPrompt] = useState<InstallEvent | null>(null);
  const [installed, setInstalled] = useState(false);
  const [links, setLinks] = useState<InstallerLinks>({ windows: null, android: null });

  useEffect(() => {
    const controller = new AbortController();
    void fetch("/downloads/installers.json", { cache: "no-store", signal: controller.signal })
      .then((response) => response.ok ? response.json() : null)
      .then((value) => setLinks(installerLinks(value)))
      .catch(() => {});
    setInstalled(window.matchMedia("(display-mode: standalone)").matches);
    const onPrompt = (e: Event) => {
      e.preventDefault();
      setPrompt(e as InstallEvent);
    };
    const onInstalled = () => setInstalled(true);
    window.addEventListener("beforeinstallprompt", onPrompt);
    window.addEventListener("appinstalled", onInstalled);
    return () => {
      controller.abort();
      window.removeEventListener("beforeinstallprompt", onPrompt);
      window.removeEventListener("appinstalled", onInstalled);
    };
  }, []);

  const install = async () => {
    if (!prompt) {
      toast.info(
        "Open Tensai in Chrome or Edge on the published site, then use the browser menu → Install Tensai. On iPhone: Share → Add to Home Screen.",
      );
      return;
    }
    await prompt.prompt();
    await prompt.userChoice;
    setPrompt(null);
  };

  return (
    <div className="mt-6 flex flex-col gap-3 rounded-lg border border-border bg-card p-4 md:flex-row md:items-center md:justify-between">
      <div>
        <div className="font-semibold">Run Tensai as its own app</div>
        <div className="text-sm text-muted-foreground">
          Windows installer · Android APK
        </div>
      </div>
      <div className="flex flex-wrap gap-2">
        <Button variant="secondary" onClick={install} disabled={installed}>
          <MonitorDown className="h-4 w-4" /> {installed ? "Installed" : "Install web app"}
        </Button>
        {links.windows ? (
          <Button asChild><a href={links.windows}><Download /> Windows EXE</a></Button>
        ) : <Button disabled><Download /> Windows EXE pending release</Button>}
        {links.android ? (
          <Button asChild><a href={links.android}><Download /> Android APK</a></Button>
        ) : <Button disabled><Download /> Android APK pending release</Button>}
      </div>
    </div>
  );
}
