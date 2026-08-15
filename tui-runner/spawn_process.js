const { spawn, exec } = require('child_process');
const { EventEmitter } = require('events');

function getFlutterDevices(cwd) {
    return new Promise((resolve) => {
        exec("flutter devices --machine", { cwd, env: process.env, windowsHide: true }, (err, stdout) => {
            if (err) return resolve([]);
            try {
                resolve(JSON.parse(stdout));
            } catch (e) {
                resolve([]);
            }
        });
    });
}

async function waitForEmulatorDevice(avdId, cwd, box, { timeoutMs = 90000, intervalMs = 2000 } = {}) {
    const deadline = Date.now() + timeoutMs;
    const wantedEmuId = avdId.toLowerCase();

    while (Date.now() < deadline) {
        const devices = await getFlutterDevices(cwd);

        const byEmulatorId = devices.find(
            (d) => (d.emulatorId || "").toLowerCase() === wantedEmuId
        );
        if (byEmulatorId) return byEmulatorId.id;
        const anyEmulator = devices.find(
            (d) => d.emulator === true || (d.id || "").toLowerCase().startsWith("emulator-")
        );
        if (anyEmulator) return anyEmulator.id;

        box.log("Still waiting for the emulator to finish booting...");
        await new Promise((resolve) => setTimeout(resolve, intervalMs));
    }
    return null;
}

function spawnProcess(proc, box, screen) {
    box.log(`{bold}$ ${proc.cmd} ${proc.args.join(" ")}{/bold}  (cwd: ${proc.cwd})`);

    const child = spawn(proc.cmd, proc.args, {
        cwd: proc.cwd,
        shell: process.platform === "win32",
        env: process.env,
    });
    pipeOutput(child, box, screen);
    child.on("exit", (code) => {
        box.log(`{yellow-fg}--- ${proc.name} exited (code ${code}) ---{/yellow-fg}`);
        screen.render();
    });
    return child;
}

function pipeOutput(child, box, screen) {
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
}

function spawnMobileProcess(proc, box, screen) {
    const handle = new EventEmitter();
    handle.pid = undefined;
    handle.killed = false;
    handle.exitCode = null;

    const win = process.platform === "win32";
    let current = null;
    let stopped = false;

    function track(child) {
        current = child;
        handle.pid = child.pid;
    }

    handle.kill = (sig) => {
        stopped = true;
        handle.killed = true;
        if (current && current.pid && current.exitCode === null && !current.killed) {
            current.kill(sig);
        }
    };

    box.log(`{bold}$ flutter emulators --launch ${proc.emulatorId}{/bold}  (cwd: ${proc.cwd})`);
    const launcher = spawn("flutter", ["emulators", "--launch", proc.emulatorId], {
        cwd: proc.cwd,
        shell: win,
        env: process.env,
    });
    track(launcher);
    pipeOutput(launcher, box, screen);

    launcher.on("exit", (code) => {
        box.log(`{yellow-fg}--- emulator launch exited (code ${code}) ---{/yellow-fg}`);
        screen.render();

        if (stopped) {
            handle.exitCode = code;
            handle.emit("exit", code);
            return;
        }

        box.log("{bold}Waiting for emulator to boot...{/bold}");
        waitForEmulatorDevice(proc.emulatorId, proc.cwd, box, {
            timeoutMs: proc.bootTimeoutMs || 90000,
        }).then((deviceId) => {
            if (stopped) {
                handle.emit("exit", handle.exitCode ?? code);
                return;
            }
            const targetId = deviceId || proc.emulatorId;
            if (!deviceId) {
                box.log(
                    `{red-fg}Timed out waiting for '${proc.emulatorId}' to appear in ` +
                    `'flutter devices'. Falling back to '${proc.emulatorId}', which may fail.{/red-fg}`
                );
            } else {
                box.log(`{green-fg}Emulator ready — device id: ${targetId}{/green-fg}`);
            }
            screen.render();

            box.log(`{bold}$ flutter run -d ${targetId}{/bold}  (cwd: ${proc.cwd})`);
            const runner = spawn("flutter", ["run", "-d", targetId], {
                cwd: proc.cwd,
                shell: win,
                env: process.env,
            });
            track(runner);
            pipeOutput(runner, box, screen);
            runner.on("exit", (runnerCode) => {
                box.log(`{yellow-fg}--- ${proc.name} exited (code ${runnerCode}) ---{/yellow-fg}`);
                screen.render();
                handle.exitCode = runnerCode;
                handle.emit("exit", runnerCode);
            });
        });
    });

    return handle;
}

function spawnAll(processes, panes, screen) {
    return processes.map((proc, i) =>
        proc.type === "mobile"
            ? spawnMobileProcess(proc, panes[i], screen)
            : spawnProcess(proc, panes[i], screen)
    );
}
module.exports = { spawnProcess, spawnMobileProcess, spawnAll };