import { afterEach, describe, expect, it, vi } from "vitest";
import {
  decodeDevSession,
  devSigninUrl,
  encodeDevSession,
  isDevOrigin,
  isLocalDev,
} from "./dev-signin";

describe("isDevOrigin", () => {
  it.each(["http://localhost", "http://localhost:5173", "http://127.0.0.1:3000"])(
    "accepts %s",
    (origin) => expect(isDevOrigin(origin)).toBe(true),
  );

  it.each([
    "https://localhost",
    "http://localhost.evil.com",
    "http://evil.com",
    "http://localhost:5173/path",
    "http://localhost@evil.com",
    "javascript:alert(1)",
    "",
    null,
    undefined,
  ])("rejects %s", (origin) => expect(isDevOrigin(origin)).toBe(false));
});

describe("dev session encoding", () => {
  it("round-trips tokens, including characters that need escaping", () => {
    const session = { access_token: "a.b/c+d==ü", refresh_token: "r~1_2-3" };
    const encoded = encodeDevSession(session);
    expect(encoded).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(decodeDevSession(encoded)).toEqual(session);
  });

  it.each([
    null,
    undefined,
    "",
    "%%%",
    "bm90LWpzb24",
    encodeDevSession({ access_token: "x" } as never),
  ])("returns null for malformed input %s", (value) => expect(decodeDevSession(value)).toBeNull());
});

describe("devSigninUrl", () => {
  it("points at the hosted app and escapes the origin", () => {
    expect(devSigninUrl("http://localhost:5173")).toBe(
      "https://tensaizwitg.app/dev-signin?origin=http%3A%2F%2Flocalhost%3A5173",
    );
  });
});

describe("isLocalDev", () => {
  afterEach(() => vi.unstubAllGlobals());

  const at = (origin: string, userAgent = "Mozilla/5.0") => {
    vi.stubGlobal("window", { location: { origin } });
    vi.stubGlobal("navigator", { userAgent });
  };

  it("is true on localhost", () => {
    at("http://localhost:5173");
    expect(isLocalDev()).toBe(true);
  });

  it("is false on the hosted app and in the desktop app", () => {
    at("https://tensaizwitg.app");
    expect(isLocalDev()).toBe(false);
    at("http://127.0.0.1:4000", "Mozilla/5.0 HiveDesktop/1.0");
    expect(isLocalDev()).toBe(false);
  });
});
