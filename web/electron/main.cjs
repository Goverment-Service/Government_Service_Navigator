// Electron entry point for the desktop (Windows / macOS / Linux) build of the web app.
// The Vite build in dist/ is served over a custom app:// protocol instead of file://
// so absolute asset paths and BrowserRouter routes keep working.
const { app, BrowserWindow, net, protocol, shell } = require("electron");
const fs = require("node:fs");
const path = require("node:path");
const { pathToFileURL } = require("node:url");

const DIST_DIR = path.join(__dirname, "..", "dist");
const APP_ORIGIN = "app://local";

protocol.registerSchemesAsPrivileged([
  {
    scheme: "app",
    privileges: { standard: true, secure: true, supportFetchAPI: true, corsEnabled: true },
  },
]);

function resolveDistFile(requestUrl) {
  const { pathname } = new URL(requestUrl);
  const filePath = path.normalize(path.join(DIST_DIR, decodeURIComponent(pathname)));

  // Block path traversal and fall back to index.html for client-side routes.
  if (!filePath.startsWith(DIST_DIR) || !fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    return path.join(DIST_DIR, "index.html");
  }
  return filePath;
}

function createWindow() {
  const win = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1024,
    minHeight: 700,
    autoHideMenuBar: true,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  // Open target="_blank" / external links in the system browser.
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (!url.startsWith(APP_ORIGIN)) shell.openExternal(url);
    return { action: "deny" };
  });

  const devServerUrl = process.env.VITE_DEV_SERVER_URL;
  win.loadURL(devServerUrl || `${APP_ORIGIN}/`);
}

app.whenReady().then(() => {
  protocol.handle("app", (request) => net.fetch(pathToFileURL(resolveDistFile(request.url)).toString()));

  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
