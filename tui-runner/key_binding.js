const { spawn } = require('child_process');

function setupKeyBindings({ screen, panes, children }) {
    let focusIndex = 0;
    panes[focusIndex].focus();

    screen.key(['tab'], () => {
        focusIndex = (focusIndex + 1) % panes.length;
        panes[focusIndex].focus();
        screen.render();
    });
    let shuttingDown = false;
    function shutdown() {
        if (shuttingDown) return;
        shuttingDown = true;

        screen.destroy();
        console.log("Shutting down backend/web processes...");

        const killPromises = children.map((child) => {
            return new Promise((resolve) => {
                if (!child.pid || child.killed || child.exitCode !== null) {
                    return resolve();
                }
                if (process.platform === "win32") {
                    const killer = spawn("taskkill", ["/pid", child.pid, "/f", "/t"]);
                    killer.on("exit", () => resolve());
                    killer.on("error", () => resolve());
                } else {
                    child.once("exit", () => resolve());
                    child.kill("SIGTERM");
                    setTimeout(() => {
                        if (child.exitCode === null) child.kill("SIGKILL");
                        resolve();
                    }, 3000);
                }
            });
        });
        const timeout = new Promise((resolve) => setTimeout(resolve, 5000));
        Promise.race([Promise.all(killPromises), timeout]).then(() => {
            console.log("Done.All processes stopped.");
            process.exit(0);
        });
    }
    screen.key(['q', 'C-c'], shutdown);
    process.on('SIGINT', shutdown);
    return { shutdown };
}
module.exports = { setupKeyBindings };
