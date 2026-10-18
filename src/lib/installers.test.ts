import { describe, expect, it } from "vitest";
import { installerLinks } from "./installers";

describe("single-file installers", () => {
  it("accepts a Windows EXE", () => {
    expect(installerLinks({ windows: "https://example.com/Tensai-Setup.exe" }).windows).toBe("https://example.com/Tensai-Setup.exe");
  });
  it("accepts an Android APK", () => {
    expect(installerLinks({ android: "https://example.com/Tensai.apk" }).android).toBe("https://example.com/Tensai.apk");
  });
  it("never presents source ZIPs or insecure links as installers", () => {
    expect(installerLinks({ windows: "https://example.com/source.zip", android: "http://example.com/Tensai.apk" })).toEqual({ windows: null, android: null });
  });
});