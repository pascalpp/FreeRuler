#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const readline = require("readline");
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

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    stdio: ["ignore", "inherit", "inherit"],
    ...options,
  });

  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }

  if (result.status !== 0) {
    process.exit(result.status === null ? 1 : result.status);
  }

  if (result.signal) {
    console.error(`${command} exited due to signal ${result.signal}.`);
    process.exit(1);
  }
}

function gitOutput(args) {
  const result = spawnSync("git", args, {
    cwd: root,
    encoding: "utf8",
  });

  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }

  if (result.status !== 0) {
    process.stderr.write(result.stderr);
    process.exit(result.status === null ? 1 : result.status);
  }

  return result.stdout.trim();
}

async function readLine(lineIterator, text) {
  process.stdout.write(text);
  const nextLine = await lineIterator.next();
  return nextLine.done ? "" : nextLine.value.trim();
}

function readKey(text) {
  return new Promise(resolve => {
    process.stdout.write(text);
    const wasRaw = process.stdin.isRaw;

    process.stdin.setRawMode(true);
    process.stdin.resume();
    process.stdin.once("data", buffer => {
      if (!wasRaw) {
        process.stdin.setRawMode(false);
      }

      const input = buffer.toString("utf8");
      if (input === "\u0003") {
        process.stdout.write("^C\n");
        process.exit(130);
      }

      const key = input === "\r" || input === "\n" ? "" : input[0];
      process.stdout.write(key ? `${key}\n` : "\n");
      resolve(key);
    });
  });
}

async function promptForInput(lineIterator, text) {
  if (process.stdin.isTTY) {
    return readKey(text);
  }

  return readLine(lineIterator, text);
}

(async () => {
  const readlineInterface = process.stdin.isTTY ? null : readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false,
  });
  const lineIterator = readlineInterface ? readlineInterface[Symbol.asyncIterator]() : null;

  const choice = (await promptForInput(lineIterator, prompt)) || "c";
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
    readlineInterface?.close();
    process.exit(0);
    break;
  default:
    console.error(`Unknown choice: ${choice}`);
    readlineInterface?.close();
    process.exit(1);
  }

  const buildNumber = gitOutput(["rev-list", "--count", "HEAD"]);

  run(process.execPath, [path.join(__dirname, "set-version.js"), nextVersion, buildNumber]);

  const answer = await promptForInput(lineIterator, `Do you want to commit and push v${nextVersion} (${buildNumber})? [Y/n] `);
  readlineInterface?.close();
  const normalizedAnswer = answer.toLowerCase();

  if (normalizedAnswer === "" || normalizedAnswer === "y" || normalizedAnswer === "yes") {
    run("git", ["add", "package.json", "Free Ruler.xcodeproj/project.pbxproj"]);
    run("git", ["commit", "-m", `Bump version to ${nextVersion}`]);
    run("git", ["push", "origin", "main"]);
    console.log(`Committed and pushed v${nextVersion} (${buildNumber}).`);
    process.exit(0);
  }

  if (normalizedAnswer === "n" || normalizedAnswer === "no") {
    console.log(`Updated version to ${nextVersion} and build ${buildNumber}. Commit skipped.`);
    process.exit(0);
  }

  console.error(`Unknown choice: ${answer}`);
  process.exit(1);
})();
