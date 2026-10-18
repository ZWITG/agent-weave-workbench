import { useCallback, useEffect, useRef, useState } from "react";

export type FreeVoiceStatus = "idle" | "loading" | "listening" | "thinking" | "speaking";

const SAMPLE_RATE = 16000;
const THRESHOLD = 0.015;
const SILENCE_MS = 900;
const MIN_SPEECH_MS = 350;

/**
 * Credit-free voice: on-device Whisper hears you, the agent answers via the chat
 * endpoint (with whichever AI the agent uses), and the computer's own voice speaks.
 */
export function useFreeVoice({ onUtterance }: { onUtterance: (text: string) => Promise<string> }) {
  const [status, setStatus] = useState<FreeVoiceStatus>("idle");
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState("");
  const [muted, setMuted] = useState(false);
  const worker = useRef<Worker | null>(null);
  const stream = useRef<MediaStream | null>(null);
  const ctx = useRef<AudioContext | null>(null);
  const statusRef = useRef<FreeVoiceStatus>("idle");
  const mutedRef = useRef(false);
  const onUtteranceRef = useRef(onUtterance);
  onUtteranceRef.current = onUtterance;
  mutedRef.current = muted;
  const set = (s: FreeVoiceStatus) => {
    statusRef.current = s;
    setStatus(s);
  };

  const stop = useCallback(() => {
    window.speechSynthesis?.cancel();
    stream.current?.getTracks().forEach((t) => t.stop());
    stream.current = null;
    void ctx.current?.close();
    ctx.current = null;
    set("idle");
  }, []);

  useEffect(
    () => () => {
      stop();
      worker.current?.terminate();
    },
    [stop],
  );

  const speak = (text: string) =>
    new Promise<void>((resolve) => {
      const synth = window.speechSynthesis;
      if (!synth || !text) return resolve();
      const u = new SpeechSynthesisUtterance(text.replace(/[*#`_>]/g, "").slice(0, 2000));
      u.onend = () => resolve();
      u.onerror = () => resolve();
      synth.speak(u);
    });

  const transcribe = (audio: Float32Array) =>
    new Promise<string>((resolve, reject) => {
      const w = worker.current!;
      const id = Math.random();
      const handler = (e: MessageEvent) => {
        if (e.data.type === "text" && e.data.id === id) {
          w.removeEventListener("message", handler);
          resolve(e.data.text as string);
        } else if (e.data.type === "error") {
          w.removeEventListener("message", handler);
          reject(new Error(e.data.message));
        }
      };
      w.addEventListener("message", handler);
      w.postMessage({ type: "transcribe", id, audio }, [audio.buffer]);
    });

  const handleSegment = async (audio: Float32Array) => {
    set("thinking");
    try {
      const text = await transcribe(audio);
      if ((statusRef.current as FreeVoiceStatus) === "idle") return;
      if (!text || /^\[.*\]$|^\(.*\)$/.test(text)) return set("listening");
      const reply = await onUtteranceRef.current(text);
      if ((statusRef.current as FreeVoiceStatus) === "idle") return;
      set("speaking");
      await speak(reply);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Voice failed");
    }
    if ((statusRef.current as FreeVoiceStatus) !== "idle") set("listening");
  };

  const start = useCallback(async () => {
    setError("");
    set("loading");
    try {
      stream.current = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true, channelCount: 1 },
      });
      if (!worker.current) {
        worker.current = new Worker(new URL("../lib/whisper.worker.ts", import.meta.url), {
          type: "module",
        });
        worker.current.addEventListener("message", (e) => {
          if (e.data.type === "progress") setProgress(Math.round(e.data.progress));
        });
      }
      await new Promise<void>((resolve, reject) => {
        const w = worker.current!;
        const h = (e: MessageEvent) => {
          if (e.data.type === "ready") {
            w.removeEventListener("message", h);
            resolve();
          }
          if (e.data.type === "error") {
            w.removeEventListener("message", h);
            reject(new Error(e.data.message));
          }
        };
        w.addEventListener("message", h);
        w.postMessage({ type: "load" });
      });
      if (!stream.current) return;
      const ac = new AudioContext({ sampleRate: SAMPLE_RATE });
      ctx.current = ac;
      const source = ac.createMediaStreamSource(stream.current);
      const proc = ac.createScriptProcessor(4096, 1, 1);
      let chunks: Float32Array[] = [];
      let speechMs = 0;
      let silentMs = 0;
      proc.onaudioprocess = (ev) => {
        if (statusRef.current !== "listening" || mutedRef.current) return;
        const data = new Float32Array(ev.inputBuffer.getChannelData(0));
        const ms = (data.length / SAMPLE_RATE) * 1000;
        let sum = 0;
        for (const v of data) sum += v * v;
        const loud = Math.sqrt(sum / data.length) > THRESHOLD;
        if (loud) {
          speechMs += ms;
          silentMs = 0;
          chunks.push(data);
        } else if (chunks.length) {
          silentMs += ms;
          chunks.push(data);
          if (silentMs >= SILENCE_MS) {
            const segment = speechMs >= MIN_SPEECH_MS ? chunks : null;
            chunks = [];
            speechMs = 0;
            silentMs = 0;
            if (segment) {
              const all = new Float32Array(segment.reduce((n, c) => n + c.length, 0));
              let o = 0;
              for (const c of segment) {
                all.set(c, o);
                o += c.length;
              }
              void handleSegment(all);
            }
          }
        }
      };
      source.connect(proc);
      proc.connect(ac.destination);
      set("listening");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not start voice");
      stop();
    }
  }, [stop]);

  return { status, progress, error, muted, setMuted, start, stop };
}
