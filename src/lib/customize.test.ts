import { describe, expect, it } from "vitest";
import { parseConfig, themeVars } from "./customize";

describe("customization", () => {
  it("keeps valid buttons and pages", () => {
    const c = parseConfig({
      buttons: [
        { id: "a", label: "Go", place: "sidebar", action: { type: "link", url: "https://x.y" } },
      ],
      pages: [{ id: "p", slug: "notes", title: "Notes", inNav: true, blocks: [] }],
    });
    expect(c.buttons).toHaveLength(1);
    expect(c.pages[0]!.slug).toBe("notes");
  });
  it("ignores a broken stored config instead of crashing", () => {
    expect(parseConfig({ buttons: "nope" }).buttons).toEqual([]);
  });
  it("applies the chosen primary colour", () => {
    expect(themeVars({ primary: "#ff0000" })["--primary"]).toBe("#ff0000");
  });
  it("turning dots off hides the dot grid", () => {
    expect(themeVars({ dots: false })["--dot"]).toBe("transparent");
  });
});
