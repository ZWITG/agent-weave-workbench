export type InstallerLinks = { windows: string | null; android: string | null };

export function installerLinks(value: unknown): InstallerLinks {
  const row = value && typeof value === "object" ? (value as Record<string, unknown>) : {};
  const link = (key: string, extension: string) => {
    try {
      const url = new URL(String(row[key] ?? ""));
      return url.protocol === "https:" && url.pathname.endsWith(extension) ? url.href : null;
    } catch {
      return null;
    }
  };
  return { windows: link("windows", ".exe"), android: link("android", ".apk") };
}
