import { LOCAL_HEADER } from "./constants";

export const isLocalMode = () => process.env["HIVE_LOCAL"] === "1";

/**
 * Only the Hive desktop window may use on-computer storage: Electron adds a secret
 * per-launch header to its own requests, and the Host must be the local address.
 */
export function isTrustedLocalRequest(request: Request) {
  if (!isLocalMode()) return false;
  const token = process.env["HIVE_LOCAL_TOKEN"];
  const host = request.headers.get("host") ?? "";
  return (
    !!token &&
    request.headers.get(LOCAL_HEADER) === token &&
    /^(127\.0\.0\.1|localhost):\d+$/.test(host)
  );
}

export function rejectUntrusted(request: Request) {
  return isTrustedLocalRequest(request) ? null : new Response("Not found", { status: 404 });
}
