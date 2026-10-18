import { describe, expect, it } from "vitest";
import { resolveProviderKind } from "./ai-settings";

describe("resolveProviderKind", () => {
  it("agent choice overrides the default", () => {
    expect(resolveProviderKind("ollama", "custom")).toBe("ollama");
  });
  it("'default' agents follow the owner's default", () => {
    expect(resolveProviderKind("default", "custom")).toBe("custom");
  });
  it("falls back to built-in AI when nothing is set", () => {
    expect(resolveProviderKind("default", null)).toBe("lovable");
  });
});
