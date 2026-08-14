const readline = require('readline');
const { execSync } = require('child_process');

function ask(question) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });
    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            rl.close();
            resolve(answer.trim());
        });
    });
}
async function askYesNo(question) {
    const answer = (await ask(question)).toLowerCase();
    return answer === 'y' || answer === 'yes';
}
function listEmulators() {
    try {
        const output = execSync("flutter emulators", { encoding: "utf8" });
        const lines = output
            .split(/\r?\n/)
            .map((l) => l.trim())
            .filter(Boolean)
            .filter((l) => !/available emulator/i.test(l))
            .filter((l) => !/^id\s+.*name/i.test(l));

        return lines
            .map((line) => {
                const parts = line.split("\u2022").map((p) => p.trim());
                return { id: parts[0], name: parts[1] || parts[0] };
            })
            .filter((e) => e.id);
    } catch (e) {
        console.log(
            "Could not list emulators (is Flutter installed and on PATH?)."
        );
        return [];
    }
}
async function selectEmulator() {
    const emulators = listEmulators();
    if (emulators.length === 0) {
        console.log("No emulators found. Create one with `flutter emulators --create`.");
        return null;
    }
    console.log("\nAvailable emulators:");
    emulators.forEach((e, i) => console.log(`  ${i + 1}) ${e.name} (${e.id})`));

    const answer = await ask(`\nSelect an emulator [1-${emulators.length}]: `);
    const idx = parseInt(answer, 10) - 1;

    if(Number.isNaN(idx) || idx < 0 || idx >= emulators.length) {
        console.log(`Invalid selection, defaulting to "${emulators[0].name}".`);
        return emulators[0];
    }
    return emulators[idx];
}
module.exports = { ask, askYesNo, listEmulators, selectEmulator };