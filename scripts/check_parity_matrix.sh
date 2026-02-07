#!/usr/bin/env bash
set -euo pipefail

MATRIX_FILE="SteamDBCompanion/Core/Routing/parity_matrix.json"

if [[ ! -f "$MATRIX_FILE" ]]; then
  echo "Missing parity matrix: $MATRIX_FILE"
  exit 1
fi

node <<'NODE'
const fs = require("fs");
const matrixPath = "SteamDBCompanion/Core/Routing/parity_matrix.json";
const registryPath = "SteamDBCompanion/Core/Routing/RouteRegistry.swift";
const backendPath = "backend/src/index.ts";
const raw = fs.readFileSync(matrixPath, "utf8");
const data = JSON.parse(raw);

if (!Array.isArray(data.routes) || data.routes.length === 0) {
  throw new Error("routes must be a non-empty array");
}

const allowedModes = new Set(["native", "webFallback"]);
const allowedGroups = new Set(["home", "search", "app", "charts", "sales", "calendar", "rankings", "utility", "entities", "unknown"]);

for (const route of data.routes) {
  const required = ["path", "title", "mode", "group", "enabled"];
  for (const key of required) {
    if (!(key in route)) {
      throw new Error(`route missing required key: ${key}`);
    }
  }

  if (typeof route.path !== "string" || route.path.length === 0) {
    throw new Error("route.path must be a non-empty string");
  }

  if (!allowedModes.has(route.mode)) {
    throw new Error(`invalid route.mode: ${route.mode}`);
  }

  if (!allowedGroups.has(route.group)) {
    throw new Error(`invalid route.group: ${route.group}`);
  }
}

const matrixSet = new Set(data.routes.map((route) => route.path));

function parseRouteRegistryPaths(source) {
  const matches = source.matchAll(/RouteDescriptor\(path:\s*"([^"]+)"/g);
  const set = new Set();
  for (const match of matches) {
    set.add(match[1]);
  }
  return set;
}

function parseBackendRoutePaths(source) {
  const routeBlockMatch = source.match(/const ROUTES:[\s\S]*?=\s*\[([\s\S]*?)\];/);
  if (!routeBlockMatch) {
    throw new Error("Unable to parse ROUTES constant in backend/src/index.ts");
  }
  const block = routeBlockMatch[1];
  const matches = block.matchAll(/path:\s*"([^"]+)"/g);
  const set = new Set();
  for (const match of matches) {
    set.add(match[1]);
  }
  return set;
}

function diff(nameA, setA, nameB, setB) {
  const missing = [...setA].filter((item) => !setB.has(item));
  const extra = [...setB].filter((item) => !setA.has(item));
  if (missing.length || extra.length) {
    throw new Error(
      `${nameA} vs ${nameB} mismatch.\n` +
      `Missing in ${nameB}: ${missing.join(", ") || "(none)"}\n` +
      `Extra in ${nameB}: ${extra.join(", ") || "(none)"}`
    );
  }
}

const registryRaw = fs.readFileSync(registryPath, "utf8");
const backendRaw = fs.readFileSync(backendPath, "utf8");

const registrySet = parseRouteRegistryPaths(registryRaw);
const backendSet = parseBackendRoutePaths(backendRaw);

diff("parity_matrix.json", matrixSet, "RouteRegistry.defaultDescriptors", registrySet);
diff("parity_matrix.json", matrixSet, "backend ROUTES", backendSet);

console.log(`Parity matrix OK. Routes aligned: ${data.routes.length}`);
NODE
