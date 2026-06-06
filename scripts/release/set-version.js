#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "../..");
const packagePath = path.join(root, "package.json");
const projectPath = path.join(root, "Free Ruler.xcodeproj/project.pbxproj");
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

let project = fs.readFileSync(projectPath, "utf8");
project = project.replace(/MARKETING_VERSION = [^;]+;/g, `MARKETING_VERSION = ${version};`);

if (build) {
  project = project.replace(/CURRENT_PROJECT_VERSION = [^;]+;/g, `CURRENT_PROJECT_VERSION = ${build};`);
}

fs.writeFileSync(projectPath, project);

console.log(`Set package.json and Xcode MARKETING_VERSION to ${version}.`);
if (build) {
  console.log(`Set Xcode CURRENT_PROJECT_VERSION to ${build}.`);
}
