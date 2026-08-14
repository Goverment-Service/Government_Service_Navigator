const path = require('path');
const {setupScreen} = require('./screen_setup');
const {spawnAll} = require('./spawn_process');
const {setupKeyBindings} = require('./key_binding');

const Process =[
    {
        name: "backend",
        cmd: "dotnet",
        args: ["run"],
        cwd: path.join(__dirname, "../backend/src"),
        color: "green",
    },
    {
        name: "web",
        cmd: "npm",
        args: ["run", "dev"],
        cwd: path.join(__dirname, "../web"),
        color: "cyan",
    }
];
function run() {
    const {screen, panes} = setupScreen(Process);
    const children = spawnAll(Process, panes, screen);
    setupKeyBindings({screen, panes, children});
    screen.render();
}
module.exports = {run, Process};