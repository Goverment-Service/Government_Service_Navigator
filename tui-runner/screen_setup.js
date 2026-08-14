const blessed = require("blessed");
const { setupHeader } = require("./header");

function setupScreen(processes, title) {
  const screen = blessed.screen({
    smartCSR: true,
    title: "GSN Dev Runner",
  });

  const { height: headerHeight } = setupHeader(screen, title);
  const bottomReserved = 1;
  const paneHeight = `100%-${headerHeight + bottomReserved}`;

  const panes = processes.map((proc, i) =>
    blessed.log({
      parent: screen,
      label: ` ${proc.name} `,
      top: headerHeight,
      left: `${(100 / processes.length) * i}%`,
      width: `${100 / processes.length}%`,
      height: paneHeight,
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