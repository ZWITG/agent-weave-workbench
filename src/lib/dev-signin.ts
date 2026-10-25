import { isDesktop } from "./ai-settings";

/** Google sign-in only works on Lovable hosting, so localhost borrows a session from here. */
export const HOSTED_ORIGIN: string =
  (import.meta.env["VITE_HOSTED_ORIGIN"] as string | undefined) ?? "https://tensaizwitg.app";

export type DevSession = { access_token: string; refresh_token: string };

/** Tokens are only ever handed to a loopback dev server, never to another site. */
export function isDevOrigin(origin: string | null | undefined): origin is string {
  return (
    typeof origin === "string" && /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/.test(origin)
  );
}

export function isLocalDev() {
  if (typeof window === "undefined" || isDesktop()) return false;
  return isDevOrigin(window.location.origin);
}

export function encodeDevSession(session: DevSession) {
  const bytes = new TextEncoder().encode(JSON.stringify(session));
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function decodeDevSession(value: string | null | undefined): DevSession | null {
  if (!value) return null;
  try {
    const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
    const binary = atob(base64 + "=".repeat((4 - (base64.length % 4)) % 4));
    const parsed = JSON.parse(
      new TextDecoder().decode(Uint8Array.from(binary, (c) => c.charCodeAt(0))),
    );
    if (typeof parsed?.access_token !== "string" || typeof parsed?.refresh_token !== "string")
      return null;
    return { access_token: parsed.access_token, refresh_token: parsed.refresh_token };
  } catch {
    return null;
  }
}

export const devSigninUrl = (origin: string) =>
  `${HOSTED_ORIGIN}/dev-signin?origin=${encodeURIComponent(origin)}`;
