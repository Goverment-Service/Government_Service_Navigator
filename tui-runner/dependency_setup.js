const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

function exists(p) {
    try {
        return fs.existsSync(p);
    } catch (err) {
        return false;
    }
}

function runSync(cmd, args, cwd, label) {
    console.log(`\n${label}`);
    console.log(`$ ${cmd} ${args.join(" ")}  (cwd: ${cwd})\n`);

    const result = spawnSync(cmd, args, {
        cwd,
        stdio: "inherit",
        shell: process.platform === "win32",
        env: process.env,
    });
    if (result.error) {
        console.error(`Failed to run "${cmd} ${args.join(" ")}": ${result.error.message}`);
        return false;
    }
    if (result.status !== 0) {
        console.error(`"${cmd} ${args.join(" ")}" exited with code ${result.status}`);
        return false;
    }
    return true;
}
/**
 * npm-based projects (the runner itself, and /web):
 * install if node_modules is missing, then run npm install
 */
function ensureNodeModules(dir, label) {
    if (!exists(dir)) return true;
    if (!exists(path.join(dir, "node_modules"))) return true;

    return runSync("npm", ["install"], dir, `Installing dependencies for ${label}...`);
}
/**
 * .NET backend: restore if there's a project but no resolved assests file yet.
 */
function ensureDotnetRestore(dir, label) {
    if (!exists(dir)) return true;
    const hasProject = fs.readdirSync(dir).some((f) => f.endsWith(".csproj") || f.endsWith(".sln"));
    if (!hasProject) return true;
    if (exists(path.join(dir, "obj", "project.assets.json"))) return true;
    return runSync("dotnet", ["restore"], dir, `Restoring NuGet packages for ${label}...`);
}
/**
 * Flutter mobile app: fetch packages if .dart_tool hasn't been created yet.
 */
function ensureFlutterPackages(dir, label) {
    if (!exists(dir)) return true;
    if (exists(path.join(dir, ".dart_tool", "package_config.json"))) return true;
    return runSync("flutter", ["pub", "get"], dir, `Fetching Flutter packages for ${label}...`);
}
module.exports = {
    ensureNodeModules,
    ensureDotnetRestore,
    ensureFlutterPackages,
}