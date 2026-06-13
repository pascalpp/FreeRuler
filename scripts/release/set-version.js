#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "../..");
const packagePath = path.join(root, "package.json");
const projectPath = path.join(root, "Free Ruler.xcodeproj/project.pbxproj");
const helpInfoPath = path.join(root, "Free Ruler/FreeRuler.help/Contents/Info.plist");
const version = process.argv[2];
const build = process.argv[3] || process.env.RELEASE_BUILD;

if (!version || !/^\d+\.\d+\.\d+$/.test(version)) {
  console.error("Usage: npm run release:version -- X.Y.Z [build]");
  process.exit(1);
}

if (build && !/^\d+$/.test(build)) {
  console.error("Build number must be an integer.");
  process.exit(1);
}

const packageJson = JSON.parse(fs.readFileSync(packagePath, "utf8"));
packageJson.version = version;
fs.writeFileSync(packagePath, `${JSON.stringify(packageJson, null, 2)}\n`);

function replacePlistString(plist, key, value) {
  const pattern = new RegExp(`(<key>${key}</key>\\n\\s*<string>)[^<]+(</string>)`);
  return plist.replace(pattern, `$1${value}$2`);
}

let project = fs.readFileSync(projectPath, "utf8");
project = project.replace(/MARKETING_VERSION = [^;]+;/g, `MARKETING_VERSION = ${version};`);

if (build) {
  project = project.replace(/CURRENT_PROJECT_VERSION = [^;]+;/g, `CURRENT_PROJECT_VERSION = ${build};`);
}

fs.writeFileSync(projectPath, project);

let helpInfo = fs.readFileSync(helpInfoPath, "utf8");
helpInfo = replacePlistString(helpInfo, "CFBundleShortVersionString", version);
helpInfo = replacePlistString(helpInfo, "HPDBookKBProduct", `freeruler${version}`);

if (build) {
  helpInfo = replacePlistString(helpInfo, "CFBundleVersion", build);
}

fs.writeFileSync(helpInfoPath, helpInfo);

console.log(`Set package.json and Xcode MARKETING_VERSION to ${version}.`);
console.log("Set help book version metadata.");
if (build) {
  console.log(`Set Xcode CURRENT_PROJECT_VERSION to ${build}.`);
}
