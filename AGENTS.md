# Agent rules
- Agent execution engine lives in src/lib/engine.server.ts; client calls createRun then executeRunFn (engine.functions.ts) so the UI can navigate before the run finishes. Why: live logs stream via realtime on run_logs/runs/artifacts.
- All app tables are gated by public.is_owner(); the first signed-in user claims ownership via claim_owner(). Why: single-owner private studio.
- Agent skills are string ids (src/lib/skills.ts) mapped to tools in the engine; knowledge tools are always on. Why: shared learning across agents.
- Individual conversations use agent-derived URLs and user-scoped device records, with invited agents and editable transcript knowledge. Why: keep each ongoing conversation isolated and locally controllable.
- Text uses an authenticated UI-message stream; voice uses the shared Live relay/hook and authorizes the owner before opening a paid session. Why: preserve streaming history, privacy, and call cleanup.
