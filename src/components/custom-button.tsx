import { useNavigate } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { useState } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { createRun, executeRunFn } from "@/lib/engine.functions";
import type { CustomButton } from "@/lib/customize";

export function CustomButtonView({
  button,
  variant = "secondary",
  className,
}: {
  button: CustomButton;
  variant?: "secondary" | "default" | "ghost";
  className?: string;
}) {
  const navigate = useNavigate();
  const create = useServerFn(createRun);
  const exec = useServerFn(executeRunFn);
  const [busy, setBusy] = useState(false);

  const run = async (): Promise<void> => {
    const a = button.action;
    if (a.type === "link") {
      if (!/^https?:\/\//.test(a.url))
        return toast.error("This button's link must start with https://");
      window.open(a.url, "_blank", "noopener");
    } else if (a.type === "page") {
      navigate({ to: "/p/$slug", params: { slug: a.slug } });
    } else if (a.type === "agent") {
      navigate({
        to: "/agents/$agentId",
        params: { agentId: a.agentId },
        search: { mode: a.mode },
      });
    } else {
      setBusy(true);
      try {
        const { runId } = await create({
          data: { workflowId: a.workflowId, input: a.task || button.label },
        });
        void exec({ data: { runId } }).catch(() => {});
        navigate({ to: "/runs/$runId", params: { runId } });
      } catch (e) {
        toast.error(e instanceof Error ? e.message : "Couldn't start the workflow");
      } finally {
        setBusy(false);
      }
    }
  };

  return (
    <Button variant={variant} className={className} disabled={busy} onClick={() => void run()}>
      {button.label}
    </Button>
  );
}
