const path = require("path");
const { setupScreen } = require("./screen_setup");
const { spawnAll } = require("./spawn_process");
const { setupKeyBindings } = require("./key_binding");
const { killPorts } = require("./port_cleanup");
const { printHeader } = require("./header");
const { askYesNo, selectEmulator } = require("./mobile_prompt");
const { ensureNodeModules, ensureDotnetRestore, ensureFlutterPackages } = require("./dependency_setup");

const TITLE = "GOVERNMENT SERVICE NAVIGATOR";

const BACKEND_DIR = path.join(__dirname, "..", "backend", "src");
const WEB_DIR = path.join(__dirname, "..", "web");
const MOBILE_DIR = path.join(__dirname, "..", "mobile");

const PROCESSES = [
  {
    name: "backend",
    cmd: "dotnet",
    args: ["run"],
    cwd: BACKEND_DIR,
    color: "green",
    port: 5119,
  },
  {
    name: "web",
    cmd: "npm",
    args: ["run", "dev"],
    cwd: WEB_DIR,
    color: "cyan",
    port: 5173,
  },
];
function buildMobileProcess(emulator) {
  return {
    name: "mobile",
    type: "mobile",
    emulatorId: emulator.id,
    cwd: MOBILE_DIR,
    color: "magenta",
    port: null,
    bootTimeoutMs: 90000,
  };
}

async function run() {
  printHeader(TITLE);
  console.log("Checking dependencies...");
  const backendOk = ensureDotnetRestore(BACKEND_DIR, "backend");
  const webOk = ensureNodeModules(WEB_DIR, "web");

  if (backendOk && webOk) {
    console.log("Dependencies ready.\n");
  } else {
    console.log(""); 
    if (!backendOk) console.log(`  - backend setup failed (${BACKEND_DIR})`);
    if (!webOk) console.log(`  - web setup failed (${WEB_DIR})`);
    const proceedAnyway = await askYesNo(
      "\nDependency setup had errors above. Start the TUI anyway? (y/n): "
    );
    if (!proceedAnyway) {
      console.log("Aborted. Fix the errors above and try again.");
      process.exit(1);
    }
  }

  const wantsMobile = await askYesNo("Run mobile app? (y/n): ");
  const processes = [...PROCESSES];

  if (wantsMobile) {
    const emulator = await selectEmulator();
    if (emulator) {
      ensureFlutterPackages(MOBILE_DIR, "mobile");
      processes.push(buildMobileProcess(emulator));
    } else {
      console.log("Skipping mobile app — no emulator selected.\n");
    }
  }
  killPorts(processes.map((p) => p.port));

  const { screen, panes } = setupScreen(processes, TITLE);
  const children = spawnAll(processes, panes, screen);
  setupKeyBindings({ screen, panes, children });

  screen.render();
}

module.exports = { run, PROCESSES, buildMobileProcess };