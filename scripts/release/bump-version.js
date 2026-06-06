#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const root = path.resolve(__dirname, "../..");
const packagePath = path.join(root, "package.json");
const packageJson = JSON.parse(fs.readFileSync(packagePath, "utf8"));
const currentVersion = packageJson.version;
const match = currentVersion.match(/^(\d+)\.(\d+)\.(\d+)$/);

if (!match) {
  console.error(`Cannot bump non-semver package version: ${currentVersion}`);
  process.exit(1);
}

const prompt = "Do you want to bump the version?\n(Major = M, minor = m, patch = p, cancel = c [c]): ";

process.stdout.write(prompt);
process.stdin.setEncoding("utf8");
process.stdin.resume();
process.stdin.once("data", input => {
  const choice = input.trim() || "c";
  const major = Number(match[1]);
  const minor = Number(match[2]);
  const patch = Number(match[3]);

  let nextVersion;
  switch (choice) {
  case "M":
    nextVersion = `${major + 1}.0.0`;
    break;
  case "m":
    nextVersion = `${major}.${minor + 1}.0`;
    break;
  case "p":
    nextVersion = `${major}.${minor}.${patch + 1}`;
    break;
  case "c":
    console.log("Canceled.");
    process.exit(0);
    break;
  default:
    console.error(`Unknown choice: ${choice}`);
    process.exit(1);
  }

  const result = spawnSync(process.execPath, [path.join(__dirname, "set-version.js"), nextVersion], {
    cwd: root,
    stdio: "inherit",
  });

  process.exit(result.status || 0);
});
