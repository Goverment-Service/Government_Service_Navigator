const { spawn } = require('child_process');

/**
 * Spawns one process and streams its stdout/stderr into the given pane.
 * @param {{name:string, cmd:string, args:string[], cwd:string}} proc
 * @param {blessed.Widgets.Log} box - the pane to log into
 * @param {blessed.Widgets.Screen} screen - needed to re-render after each log line
 * @returns {import('child_process').ChildProcess}
 */

function spawnProcess(proc, box, screen) {
    box.log(`{bold}$ ${proc.cmd} ${proc.args.join(" ")}{/bold}  (cwd: ${proc.cwd})`);

    const child = spawn(proc.cmd, proc.args, {
        cwd: proc.cwd,
        shell: process.platform === "win32",
        env: process.env,
    });
    child.stdout.on("data", (data) => {
        data
            .toString()
            .split(/\r?\n/)
            .filter(Boolean)
            .forEach((line) => box.log(line));
        screen.render();
    });
    child.stderr.on("data", (data) => {
        data
            .toString()
            .split(/\r?\n/)
            .filter(Boolean)
            .forEach((line) => box.log(`{red-fg}${line}{/red-fg}`));
        screen.render();
    });
    child.on("exit", (code) => {
        box.log(`{yellow-fg}--- ${proc.name} exited (code ${code}) ---{/yellow-fg}`);
        screen.render();
    });
    return child;
}
/**
 * Spawns every process in `processes`, wiring each to its matching pane.
 * @param {Array} processes
 * @param {blessed.Widgets.Log[]} panes - same order/length as processes
 * @param {blessed.Widgets.Screen} screen
 * @returns {import('child_process').ChildProcess[]}
 */

function spawnAll(processes,panes,screen) {
    return processes.map((proc, i) => spawnProcess(proc, panes[i], screen));
}
module.exports = { spawnProcess, spawnAll };