import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const matrix = JSON.parse(readFileSync(new URL("../../SteamDBCompanion/Core/Routing/parity_matrix.json", import.meta.url), "utf8"));
const workerSource = readFileSync(new URL("../src/index.ts", import.meta.url), "utf8");

function parseBackendRoutes(source) {
  const routeBlockMatch = source.match(/const ROUTES:[\s\S]*?=\s*\[([\s\S]*?)\];/);
  assert.ok(routeBlockMatch, "ROUTES constant should be present");
  return [...routeBlockMatch[1].matchAll(/path:\s*"([^"]+)"/g)].map((match) => match[1]);
}

test("backend route metadata stays aligned with parity matrix", () => {
  const matrixRoutes = matrix.routes.map((route) => route.path).sort();
  const backendRoutes = parseBackendRoutes(workerSource).sort();
  assert.deepEqual(backendRoutes, matrixRoutes);
});

test("utility web routes keep known safe fallbacks", () => {
  assert.match(workerSource, /path:\s*"\/events"[\s\S]*webURLOverride:\s*"https:\/\/steamdb\.info\/sales\/history\/"[\s\S]*fallbackWebURL:\s*"https:\/\/store\.steampowered\.com\/news\/"/);
  assert.match(workerSource, /path:\s*"\/wishlist"[\s\S]*webURLOverride:\s*"https:\/\/store\.steampowered\.com\/wishlist\/"/);
});
