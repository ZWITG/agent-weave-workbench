import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport, type UIMessage } from "ai";
import { useEffect, useMemo, useRef, useState } from "react";
import { MessageSquare, Mic, MicOff, PhoneOff, Play, UserPlus, Trash2, Pencil } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import type { Database } from "@/integrations/supabase/types";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Conversation,
  ConversationContent,
  ConversationScrollButton,
} from "@/components/ai-elements/conversation";
import { Message, MessageContent, MessageResponse } from "@/components/ai-elements/message";
import {
  PromptInput,
  PromptInputTextarea,
  PromptInputFooter,
  PromptInputSubmit,
} from "@/components/ai-elements/prompt-input";
import { Shimmer } from "@/components/ai-elements/shimmer";
import { useLiveVoice } from "@/hooks/use-live-voice";
import { useFreeVoice } from "@/hooks/use-free-voice";
import { useAiSettings } from "@/routes/_authenticated/settings";
import { isDesktop, resolveProviderKind } from "@/lib/ai-settings";
import { useDeviceConversations, type DeviceConversation } from "@/lib/conversation-store";
import { colorClass } from "@/lib/skills";

type Agent = Database["public"]["Tables"]["agents"]["Row"];
export function AgentConversation({
  agent,
  agents,
  userId,
  saved,
  initialMode,
}: {
  agent: Agent;
  agents: Agent[];
  userId: string;
  saved?: DeviceConversation | undefined;
  initialMode: "text" | "voice";
}) {
  const device = useDeviceConversations(userId);
  const latest = useRef(device);
  latest.current = device;
  const [mode, setMode] = useState(initialMode);
  const [invited, setInvited] = useState(saved?.invited ?? []);
  const [inviteOpen, setInviteOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [draft, setDraft] = useState("");
  const [input, setInput] = useState("");
  const [token, setToken] = useState("");
  const textarea = useRef<HTMLTextAreaElement>(null);
  const extra = useRef({ invited, knowledge: saved?.knowledge ?? "" });
  extra.current = {
    invited,
    knowledge: device.records[agent.id]?.knowledge ?? saved?.knowledge ?? "",
  };
  useEffect(() => {
    void supabase.auth.getSession().then(({ data }) => setToken(data.session?.access_token ?? ""));
  }, []);
  const lastReply = useRef("");
  const { data: aiSettings } = useAiSettings();
  const [desktop, setDesktop] = useState(false);
  useEffect(() => setDesktop(isDesktop()), []);
  const freeVoiceMode =
    desktop || resolveProviderKind(agent.provider, aiSettings?.default_provider) !== "lovable";
  const transport = useMemo(
    () =>
      new DefaultChatTransport({
        api: "/api/chat",
        headers: async () => {
          const { data } = await supabase.auth.getSession();
          return { Authorization: `Bearer ${data.session?.access_token ?? ""}` };
        },
        body: () => ({ agentId: agent.id, ...extra.current }),
      }),
    [agent.id],
  );
  const { messages, sendMessage, status, stop, error, setMessages } = useChat({
    id: agent.id,
    messages: saved?.messages ?? [],
    transport,
    onFinish: ({ messages: completed, message }) => {
      lastReply.current = message.parts.map((p) => (p.type === "text" ? p.text : "")).join("");
      latest.current.update(agent.id, { messages: completed, invited: extra.current.invited });
      textarea.current?.focus();
    },
  });
  const busy = status === "submitted" || status === "streaming";
  const messagesRef = useRef(messages);
  messagesRef.current = messages;
  const [seconds, setSeconds] = useState<number | null>(null);
  const call = useLiveVoice({
    context: { token, agentId: agent.id, invited, knowledge: extra.current.knowledge },
    onEvent: (event) => {
      if (event.type === "gateway.session.created") setSeconds(15);
      if (event.usage && typeof event.usage.seconds === "number")
        setSeconds(Math.max(15, event.usage.seconds));
      if (
        !["session.input_transcript.delta", "session.output_transcript.delta"].includes(
          event.type,
        ) ||
        typeof event["delta"] !== "string"
      )
        return;
      const role = event.type === "session.input_transcript.delta" ? "user" : "assistant";
      const current = messagesRef.current;
      const last = current[current.length - 1];
      const text = event["delta"];
      const next: UIMessage[] =
        last?.role === role && last.id.startsWith("voice-")
          ? [
              ...current.slice(0, -1),
              {
                ...last,
                parts: [
                  {
                    type: "text",
                    text: (last.parts.find((p) => p.type === "text")?.text ?? "") + text,
                  },
                ],
              },
            ]
          : [
              ...current,
              { id: `voice-${crypto.randomUUID()}`, role, parts: [{ type: "text", text }] },
            ];
      messagesRef.current = next;
      setMessages(next);
      latest.current.update(agent.id, { messages: next, invited: extra.current.invited });
    },
  });
  const free = useFreeVoice({
    onUtterance: async (text) => {
      lastReply.current = "";
      await sendMessage({ text });
      return lastReply.current;
    },
  });
  const calling =
    ["connecting", "connected", "stopping"].includes(call.status) || free.status !== "idle";
  useEffect(() => {
    if (mode === "text" && !inviteOpen && !editOpen) textarea.current?.focus();
  }, [mode, inviteOpen, editOpen, status]);
  const submit = async (text: string) => {
    if (!text.trim() || busy || calling) return;
    setInput("");
    const promise = sendMessage({ text });
    textarea.current?.focus();
    await promise;
  };
  useEffect(() => {
    if (messages.length)
      latest.current.update(agent.id, { messages, invited: extra.current.invited });
  }, [messages, busy, agent.id]);

  return (
    <section className="flex min-w-0 flex-col">
      <header className="flex flex-wrap items-center justify-between gap-4 border-b border-border pb-5">
        <div className="flex min-w-0 items-center gap-3">
          <span
            className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-md font-bold text-primary-foreground ${colorClass[agent.color] ?? "bg-primary"}`}
          >
            {agent.name.slice(0, 2).toUpperCase()}
          </span>
          <div className="min-w-0">
            <h1 className="break-words text-2xl font-bold">{agent.name}</h1>
            <p className="text-sm text-muted-foreground">{agent.role || "Agent"}</p>
          </div>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button
            variant={mode === "text" ? "default" : "outline"}
            disabled={calling}
            onClick={() => setMode("text")}
          >
            <MessageSquare /> Text
          </Button>
          <Button
            variant={mode === "voice" ? "default" : "outline"}
            disabled={busy}
            onClick={() => setMode("voice")}
          >
            <Mic /> Voice
          </Button>
          <Button variant="outline" disabled={busy || calling} onClick={() => setInviteOpen(true)}>
            <UserPlus /> Invite agent
          </Button>
        </div>
      </header>
      {!!invited.length && (
        <div className="flex flex-wrap gap-3 border-b border-border py-3 text-sm text-muted-foreground">
          With{" "}
          {agents
            .filter((a) => invited.includes(a.id))
            .map((a) => a.name)
            .join(", ")}
        </div>
      )}
      <Conversation className="h-[52vh] min-h-64">
        <ConversationContent className="px-0">
          {!messages.length && (
            <div className="py-16 text-center">
              <div className="text-lg font-semibold">{agent.name}</div>
              <p className="mt-2 text-sm text-muted-foreground">No conversation yet.</p>
            </div>
          )}
          {messages.map((message) => (
            <Message key={message.id} from={message.role} className="max-w-full">
              <MessageContent
                className={
                  message.role === "user"
                    ? "group-[.is-user]:bg-primary group-[.is-user]:text-primary-foreground"
                    : "bg-transparent text-foreground"
                }
              >
                {message.parts.map((part, index) =>
                  part.type === "text" ? (
                    <MessageResponse key={index}>{part.text}</MessageResponse>
                  ) : part.type === "reasoning" ? (
                    <details key={index} className="text-xs text-muted-foreground">
                      <summary>Thinking</summary>
                      <MessageResponse>{part.text}</MessageResponse>
                    </details>
                  ) : null,
                )}
              </MessageContent>
            </Message>
          ))}
          {status === "submitted" && <Shimmer>Thinking…</Shimmer>}
        </ConversationContent>
        <ConversationScrollButton />
      </Conversation>
      {(error || call.error || device.error) && (
        <p role="alert" className="mb-3 break-words text-sm text-destructive">
          {error?.message || call.error || free.error || device.error}
        </p>
      )}
      <audio
        ref={call.audioRef}
        controls
        className={mode === "voice" && !freeVoiceMode ? "mb-3 h-9 w-full" : "hidden"}
      />
      {mode === "voice" && freeVoiceMode ? (
        <div className="border-t border-border pt-4">
          <div className="mb-3 flex flex-wrap items-center justify-between gap-2 text-sm text-muted-foreground">
            <span>
              {free.status === "idle"
                ? "Ready to call"
                : free.status === "loading"
                  ? `Preparing free voice${free.progress ? ` · ${free.progress}%` : ""}`
                  : free.status}
            </span>
            <span>Free voice · no credits</span>
          </div>
          <div className="flex flex-wrap gap-2">
            {free.status === "idle" ? (
              <Button onClick={() => void free.start()}>
                <Mic /> Start voice call
              </Button>
            ) : (
              <Button variant="destructive" onClick={free.stop}>
                <PhoneOff /> End call
              </Button>
            )}
            {free.status !== "idle" && (
              <Button variant="outline" onClick={() => free.setMuted(!free.muted)}>
                {free.muted ? <MicOff /> : <Mic />}
                {free.muted ? "Unmute" : "Mute"}
              </Button>
            )}
          </div>
          <p className="mt-3 text-xs text-muted-foreground">
            Speak, then pause — {agent.name} answers out loud. The first call downloads a speech
            model (about 80 MB) once.
          </p>
        </div>
      ) : mode === "voice" ? (
        <div className="border-t border-border pt-4">
          <div className="mb-3 flex flex-wrap items-center justify-between gap-2 text-sm text-muted-foreground">
            <span>{call.status === "idle" ? "Ready to call" : call.status}</span>
            <span>
              {seconds === null
                ? "Uses AI credits · 15-second minimum"
                : `${seconds.toFixed(0)} billable seconds${call.finalized === false ? " · final usage unconfirmed" : ""}`}
            </span>
          </div>
          <div className="flex flex-wrap gap-2">
            {!calling ? (
              <Button
                disabled={!token}
                onClick={() => {
                  setSeconds(null);
                  call.start();
                }}
              >
                <Mic /> Start voice call
              </Button>
            ) : (
              <Button variant="destructive" onClick={call.stop}>
                <PhoneOff /> End call
              </Button>
            )}
            {calling && (
              <Button variant="outline" onClick={() => call.setMuted(!call.muted)}>
                {call.muted ? <MicOff /> : <Mic />}
                {call.muted ? "Unmute" : "Mute"}
              </Button>
            )}
            {call.playbackBlocked && (
              <Button variant="outline" onClick={call.resumePlayback}>
                <Play /> Play audio
              </Button>
            )}
          </div>
          {!calling && (
            <p className="mt-3 text-xs text-muted-foreground">
              Microphone access is needed to speak with {agent.name}.
            </p>
          )}
        </div>
      ) : (
        <PromptInput onSubmit={({ text }) => submit(text)}>
          <PromptInputTextarea
            ref={textarea}
            aria-label="Message agent"
            placeholder={`Message ${agent.name}…`}
            value={input}
            onChange={(e) => setInput(e.target.value)}
          />
          <PromptInputFooter className="justify-end">
            <PromptInputSubmit status={status} onStop={stop} disabled={!busy && !input.trim()} />
          </PromptInputFooter>
        </PromptInput>
      )}
      <div className="mt-4 flex flex-wrap justify-end gap-2">
        <Button
          variant="ghost"
          size="sm"
          disabled={busy || calling}
          onClick={() => {
            setDraft(device.records[agent.id]?.knowledge ?? "");
            setEditOpen(true);
          }}
        >
          <Pencil /> Edit saved knowledge
        </Button>
        <Button
          variant="ghost"
          size="sm"
          disabled={busy || calling}
          onClick={() => {
            if (!window.confirm("Remove this conversation and its knowledge from this device?"))
              return;
            device.remove(agent.id);
            setMessages([]);
            setInvited([]);
          }}
        >
          <Trash2 /> Remove conversation
        </Button>
      </div>
      <Dialog open={inviteOpen} onOpenChange={setInviteOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Invite agents</DialogTitle>
          </DialogHeader>
          <div className="space-y-3">
            {agents
              .filter((a) => a.id !== agent.id)
              .map((a) => (
                <label key={a.id} className="flex items-center gap-3">
                  <Checkbox
                    checked={invited.includes(a.id)}
                    onCheckedChange={(checked) => {
                      const next = checked
                        ? [...invited, a.id]
                        : invited.filter((id) => id !== a.id);
                      setInvited(next);
                      device.update(agent.id, { invited: next });
                    }}
                  />
                  <span>{a.name}</span>
                </label>
              ))}
            {agents.length === 1 && (
              <p className="text-sm text-muted-foreground">No other agents available.</p>
            )}
          </div>
          <Button onClick={() => setInviteOpen(false)}>Done</Button>
        </DialogContent>
      </Dialog>
      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Conversation knowledge · {agent.name}</DialogTitle>
          </DialogHeader>
          <Textarea
            rows={12}
            aria-label="Conversation knowledge"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
          />
          <Button
            onClick={() => {
              device.update(agent.id, { knowledge: draft });
              setEditOpen(false);
            }}
          >
            Save knowledge
          </Button>
        </DialogContent>
      </Dialog>
    </section>
  );
}
