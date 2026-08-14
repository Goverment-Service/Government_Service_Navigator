const blessed = require("blessed");

/**
 * Builds the blessed screen, one log pane per process, and the status bar.
 * @param {Array} processes - array of { name, color } (order defines pane layout)
 * @returns {{ screen: blessed.Widgets.Screen, panes: blessed.Widgets.Log[] }}
 */
function setupScreen(processes) {
  const screen = blessed.screen({
    smartCSR: true,
    title: "GSN Dev Runner",
  });

  const panes = processes.map((proc, i) =>
    blessed.log({
      parent: screen,
      label: ` ${proc.name} `,
      top: 0,
      left: `${(100 / processes.length) * i}%`,
      width: `${100 / processes.length}%`,
      height: "100%-1",
      border: { type: "line" },
      style: {
        border: { fg: proc.color },
        label: { fg: proc.color, bold: true },
      },
      scrollable: true,
      alwaysScroll: true,
      mouse: true,
      keys: true,
      tags: true,
    })
  );

  blessed.box({
    parent: screen,
    bottom: 0,
    left: 0,
    width: "100%",
    height: 1,
    content:
      " {bold}Tab{/bold}=switch pane  {bold}↑/↓{/bold}=scroll  {bold}q{/bold} / {bold}Ctrl+C{/bold}=quit all",
    tags: true,
    style: { fg: "white", bg: "blue" },
  });

  return { screen, panes };
}

module.exports = { setupScreen };