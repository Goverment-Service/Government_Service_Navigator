const { execSync } = require("child_process");
function killPort(port) {
  try {
    if (process.platform === "win32") {
      const output = execSync(`netstat -ano | findstr :${port}`, {
        encoding: "utf8",
      });
      const pids = new Set();
      output.split(/\r?\n/).forEach((line) => {
        const match = line.trim().match(/LISTENING\s+(\d+)\s*$/);
        if (match) pids.add(match[1]);
      });
      pids.forEach((pid) => {
        try {
          execSync(`taskkill /PID ${pid} /F`, { stdio: "ignore" });
          console.log(`Freed port ${port} (killed stale PID ${pid})`);
        } catch (e) {
        }
      });
    } else {
      const output = execSync(`lsof -ti:${port}`, { encoding: "utf8" });
      output
        .split(/\r?\n/)
        .filter(Boolean)
        .forEach((pid) => {
          try {
            execSync(`kill -9 ${pid}`);
            console.log(`Freed port ${port} (killed stale PID ${pid})`);
          } catch (e) {
          }
        });
    }
  } catch (e) {
  }
}
function killPorts(ports) {
  ports.filter(Boolean).forEach(killPort);
}

module.exports = { killPort, killPorts };