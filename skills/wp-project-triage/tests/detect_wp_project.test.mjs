import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT_PATH = path.join(__dirname, "..", "scripts", "detect_wp_project.mjs");

function makeTmpDir() {
  // Resolve symlinks (e.g. macOS /tmp -> /private/tmp) so path assertions
  // match what the script resolves via process.cwd().
  return fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "detect-wp-project-")));
}

function runDetect(cwd) {
  const stdout = execFileSync("node", [SCRIPT_PATH], { cwd, encoding: "utf8" });
  return JSON.parse(stdout);
}

test("wp-content root type: plugins/ and themes/ directly under repo root", () => {
  const repoRoot = makeTmpDir();
  fs.mkdirSync(path.join(repoRoot, "plugins"), { recursive: true });
  fs.mkdirSync(path.join(repoRoot, "themes"), { recursive: true });

  const report = runDetect(repoRoot);

  assert.notDeepEqual(report.project.kind, ["unknown"]);
  assert.ok(report.project.kind.includes("wp-content-root"));
  assert.equal(report.signals.hasThemesDir, true);
  assert.equal(report.signals.hasPluginsDir, true);
  assert.equal(report.signals.hasWpContentDir, true);
  assert.equal(report.signals.paths.wpContent, repoRoot);
});

test("WordPress root type: wp-content/ subdirectory holds plugins/ and themes/", () => {
  const repoRoot = makeTmpDir();
  const wpContent = path.join(repoRoot, "wp-content");
  fs.mkdirSync(path.join(wpContent, "plugins"), { recursive: true });
  fs.mkdirSync(path.join(wpContent, "themes"), { recursive: true });

  const report = runDetect(repoRoot);

  assert.ok(report.project.kind.includes("wp-site"));
  assert.ok(!report.project.kind.includes("wp-content-root"));
  assert.equal(report.signals.hasThemesDir, true);
  assert.equal(report.signals.hasPluginsDir, true);
  assert.equal(report.signals.hasWpContentDir, true);
  assert.equal(report.signals.paths.wpContent, wpContent);
});

test("standalone plugin type: single PHP file with a Plugin Name header at repo root", () => {
  const repoRoot = makeTmpDir();
  fs.writeFileSync(
    path.join(repoRoot, "my-plugin.php"),
    "<?php\n/*\nPlugin Name: My Plugin\n*/\n"
  );

  const report = runDetect(repoRoot);

  assert.ok(report.project.kind.includes("wp-plugin"));
  assert.equal(report.signals.hasThemesDir, false);
  assert.equal(report.signals.hasPluginsDir, false);
  assert.equal(report.signals.hasWpContentDir, false);
});

test("empty directory: no recognizable structure classifies as unknown", () => {
  const repoRoot = makeTmpDir();

  const report = runDetect(repoRoot);

  assert.deepEqual(report.project.kind, ["unknown"]);
  assert.equal(report.project.primary, "unknown");
});
