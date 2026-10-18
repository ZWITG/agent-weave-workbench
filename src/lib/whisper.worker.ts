/// <reference lib="webworker" />
// Free, on-device speech-to-text. The model downloads once and is cached by the browser.
import { env, pipeline, type AutomaticSpeechRecognitionPipeline } from "@huggingface/transformers";

// The desktop app ships the speech model and its runtime, so voice works with no internet.
if (/HiveDesktop/.test(self.navigator.userAgent)) {
  env.allowRemoteModels = false;
  env.localModelPath = "/models/";
  if (env.backends.onnx.wasm) env.backends.onnx.wasm.wasmPaths = "/ort/";
}

let asr: Promise<AutomaticSpeechRecognitionPipeline> | null = null;
const load = () =>
  (asr ??= pipeline("automatic-speech-recognition", "onnx-community/whisper-base", {
    dtype: "q8",
    progress_callback: (p: { status: string; progress?: number }) => {
      if (p.status === "progress")
        self.postMessage({ type: "progress", progress: p.progress ?? 0 });
    },
  }) as Promise<AutomaticSpeechRecognitionPipeline>);

self.onmessage = async (
  e: MessageEvent<{ type: "load" } | { type: "transcribe"; id: number; audio: Float32Array }>,
) => {
  try {
    const model = await load();
    if (e.data.type === "load") return self.postMessage({ type: "ready" });
    const out = (await model(e.data.audio)) as { text: string } | { text: string }[];
    const text = Array.isArray(out) ? out.map((o) => o.text).join(" ") : out.text;
    self.postMessage({ type: "text", id: e.data.id, text: text.trim() });
  } catch (err) {
    self.postMessage({
      type: "error",
      message: err instanceof Error ? err.message : "Speech recognition failed",
    });
  }
};
