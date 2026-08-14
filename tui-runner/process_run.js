const path = require("path");
const { setupScreen } = require("./screen_setup");
const { spawnAll } = require("./spawn_process");
const { setupKeyBindings } = require("./key_binding");
const { killPorts } = require("./port_cleanup");

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

function run() {
  killPorts(PROCESSES.map((p) => p.port));
  const { screen, panes } = setupScreen(PROCESSES);
  const children = spawnAll(PROCESSES, panes, screen);
  setupKeyBindings({ screen, panes, children });
  screen.render();
}

module.exports = { run, PROCESSES };