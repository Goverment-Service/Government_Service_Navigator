#!/usr/bin/env node
/**
 * GSN TUI Runner - entry point
 * Runs `dotnet run` (backend/src) and `npm run dev` (web) side by side
 * in a split-pane terminal UI, with one command.
 *
 * Logic lives in:
 *   screen_setup.js  - builds the blessed screen, panes, status bar
 *   spawn_process.js - spawns child processes and streams output into panes
 *   key_binding.js   - Tab to switch panes, q/Ctrl+C to quit everything
 *   process_run.js   - defines PROCESSES and wires the above together
 *   port_cleanup.js  - frees ports from child processes
 *   header.js        - renders the ASCII-art title header
 *   mobile_prompt.js  - prompts user to select a mobile emulator (if any)
 *   dependency_setup.js - ensures dependencies are installed (npm, dotnet, flutter)
 *
 * Usage:  node tui-runner.js
 * Quit:   q  or  Ctrl+C   (kills both child processes cleanly)
 * Switch focus / scroll:  Tab  to switch pane, Up/Down or PgUp/PgDn to scroll
 */
require("./dependency_setup").ensureNodeModules(__dirname, "tui-runner");
require("./process_run.js")
    .run()
    .catch((err) => {
        console.error(err);
        process.exit(1);
    });