// Hive desktop: starts the bundled Hive server on this computer and opens it in a window.
// Updates come from the project's GitHub releases (electron-updater).
const { app, BrowserWindow, dialog, session, shell } = require("electron");
const { spawn } = require("node:child_process");
const crypto = require("node:crypto");
const net = require("node:net");
const path = require("node:path");
const { autoUpdater } = require("electron-updater");

// Public sign-in settings for the online Hive account (publishable, safe to ship).
const SUPABASE_URL = "https://pdygioaoekpkvmxskhmr.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_k5ErVR4VJqnZX5dR4mS_uw_TKlB4rhX";
const PORT = 48217;

let server;
// Per-launch secret: only this window may use the on-computer studio.
const LOCAL_TOKEN = crypto.randomBytes(32).toString("hex");

function waitForPort(port, timeoutMs = 30000) {
  const started = Date.now();
  return new Promise((resolve, reject) => {
    const tryOnce = () => {
      const sock = net.connect(port, "127.0.0.1");
      sock.once("connect", () => { sock.end(); resolve(); });
      sock.once("error", () => {
        sock.destroy();
        if (Date.now() - started > timeoutMs) reject(new Error("Hive server did not start"));
        else setTimeout(tryOnce, 300);
      });
    };
    tryOnce();
  });
}

function startServer() {
  const root = app.isPackaged ? path.join(process.resourcesPath, "server") : path.join(__dirname, "server");
  server = spawn(process.execPath, [path.join(root, "server", "index.mjs")], {
    cwd: root,
    env: {
      ...process.env,
      ELECTRON_RUN_AS_NODE: "1",
      PORT: String(PORT),
      HOST: "127.0.0.1",
      NITRO_PORT: String(PORT),
      NITRO_HOST: "127.0.0.1",
      SUPABASE_URL,
      SUPABASE_PUBLISHABLE_KEY,
      HIVE_LOCAL: "1",
      HIVE_LOCAL_TOKEN: LOCAL_TOKEN,
      HIVE_DATA_DIR: app.getPath("userData"),
    },
    stdio: "inherit",
    windowsHide: true,
  });
  server.on("exit", (code) => {
    if (code && !app.isQuitting) dialog.showErrorBox("Hive", `The Hive engine stopped (code ${code}).`);
  });
}

async function createWindow() {
  session.defaultSession.setPermissionRequestHandler((_wc, permission, cb) =>
    cb(["media", "microphone", "audioCapture", "clipboard-sanitized-write"].includes(permission)),
  );
  session.defaultSession.webRequest.onBeforeSendHeaders(
    { urls: [`http://127.0.0.1:${PORT}/*`] },
    (details, cb) => cb({ requestHeaders: { ...details.requestHeaders, "x-hive-local": LOCAL_TOKEN } }),
  );
  const win = new BrowserWindow({
    width: 1280,
    height: 860,
    backgroundColor: "#0b0d10",
    title: "Hive",
    autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, sandbox: true },
  });
  win.webContents.setUserAgent(`${win.webContents.getUserAgent()} HiveDesktop/${app.getVersion()}`);
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (!url.startsWith(`http://127.0.0.1:${PORT}`)) {
      void shell.openExternal(url);
      return { action: "deny" };
    }
    return { action: "allow" };
  });
  await win.loadURL(`http://127.0.0.1:${PORT}/dashboard`);
}

app.whenReady().then(async () => {
  startServer();
  try {
    await waitForPort(PORT);
    await createWindow();
  } catch (e) {
    dialog.showErrorBox("Hive", String(e));
    app.quit();
  }
  if (app.isPackaged) {
    autoUpdater.autoDownload = true;
    autoUpdater.on("update-downloaded", async () => {
      const { response } = await dialog.showMessageBox({
        type: "info",
        buttons: ["Restart now", "Later"],
        message: "A new version of Hive is ready. Restart to update?",
      });
      if (response === 0) autoUpdater.quitAndInstall();
    });
    autoUpdater.checkForUpdates().catch(() => {});
  }
});

app.on("before-quit", () => {
  app.isQuitting = true;
  server?.kill();
});
app.on("window-all-closed", () => app.quit());
