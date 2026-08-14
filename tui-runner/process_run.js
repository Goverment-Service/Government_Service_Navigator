const path = require("path");
const { setupScreen } = require("./screen_setup");
const { spawnAll } = require("./spawn_process");
const { setupKeyBindings } = require("./key_binding");
const { killPorts } = require("./port_cleanup");
const { printHeader } = require("./header");
const { askYesNo, selectEmulator } = require("./mobile_prompt");

const TITLE = "GOVERNMENT SERVICE NAVIGATOR";

const PROCESSES = [
  {
    name: "backend",
    cmd: "dotnet",
    args: ["run"],
    cwd: path.join(__dirname, "..", "backend", "src"),
    color: "green",
    port: 5119,
  },
  {
    name: "web",
    cmd: "npm",
    args: ["run", "dev"],
    cwd: path.join(__dirname, "..", "web"),
    color: "cyan",
    port: 5173,
  },
];

function buildMobileProcess(emulator) {
  return {
    name: "mobile",
    type: "mobile",
    emulatorId: emulator.id,
    cwd: path.join(__dirname, "..", "mobile"),
    color: "magenta",
    port: null,
    bootTimeoutMs: 90000,
  };
}

async function run() {
  printHeader(TITLE);

  const wantsMobile = await askYesNo("\nRun mobile app? (y/n): ");

  const processes = [...PROCESSES];

  if (wantsMobile) {
    const emulator = await selectEmulator();
    if (emulator) {
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