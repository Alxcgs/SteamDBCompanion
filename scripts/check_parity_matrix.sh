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

console.log(`Parity matrix OK. Routes: ${data.routes.length}`);
NODE
