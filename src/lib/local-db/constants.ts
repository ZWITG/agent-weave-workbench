/** The single owner of the desktop app's on-computer studio. */
export const LOCAL_USER_ID = "00000000-0000-4000-8000-00000000c0de";
export const LOCAL_HEADER = "x-hive-local";

/** Tables copied to and from the online account, in parent-before-child order. */
export const SYNC_TABLES = ["agents", "workflows", "runs", "artifacts", "run_logs", "knowledge"] as const;
export const LOCAL_TABLES = [...SYNC_TABLES, "ai_settings"] as const;
export type LocalTable = (typeof LOCAL_TABLES)[number];
