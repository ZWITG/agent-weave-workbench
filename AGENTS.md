# Agent rules
- Agent execution engine lives in src/lib/engine.server.ts; client calls createRun then executeRunFn (engine.functions.ts) so the UI can navigate before the run finishes. Why: live logs stream via realtime on run_logs/runs/artifacts.
- All app tables are gated by public.is_owner(); the first signed-in user claims ownership via claim_owner(). Why: single-owner private studio.
- Agent skills are string ids (src/lib/skills.ts) mapped to tools in the engine; knowledge tools are always on. Why: shared learning across agents.
- Individual conversations use agent-derived URLs and user-scoped device records, with invited agents and editable transcript knowledge. Why: keep each ongoing conversation isolated and locally controllable.
- Text uses an authenticated UI-message stream; voice uses the shared Live relay/hook and authorizes the owner before opening a paid session. Why: preserve streaming history, privacy, and call cleanup.
- Each agent's AI is resolved server-side by src/lib/ai-provider.server.ts from public.ai_settings + agents.provider (built-in gateway, Ollama, or owner's OpenAI-compatible key). Why: let the owner run without Lovable credits.
- Voice uses the Live relay only for built-in AI on the web; otherwise the free pipeline (on-device Whisper worker + speechSynthesis) in use-free-voice.ts. Why: credit-free voice and no WebSocketPair in the desktop Node server.
- The Windows desktop app lives in desktop/ (Electron spawning the nitro node-server build made with HIVE_DESKTOP=1) and is built/published by .github/workflows/desktop.yml to GitHub releases for auto-update. Why: keep Electron out of the web app's dependencies.
