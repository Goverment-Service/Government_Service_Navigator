const blessed = require("blessed");
const figlet = require("figlet");

function setupHeader(screen, title) {
  const art = figlet.textSync(title, { font: "Mini" });

  const lines = art.split("\n");
  while (lines.length && lines[lines.length - 1].trim() === "") lines.pop();

  const height = lines.length + 2; 

  const box = blessed.box({
    parent: screen,
    top: 0,
    left: 0,
    width: "100%",
    height,
    content: lines.join("\n"),
    align: "center",
    tags: true,
    border: { type: "line" },
    style: {
      fg: "yellow",
      bold: true,
      border: { fg: "yellow" },
    },
  });

  return { box, height };
}

module.exports = { setupHeader };