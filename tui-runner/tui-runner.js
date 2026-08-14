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
 *
 * Usage:  node tui-runner.js
 * Quit:   q  or  Ctrl+C   (kills both child processes cleanly)
 * Switch focus / scroll:  Tab  to switch pane, Up/Down or PgUp/PgDn to scroll
 */

require("./process_run.js").run();