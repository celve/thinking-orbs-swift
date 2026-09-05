#!/bin/bash
# Checks what `swift test` cannot: that the checked-in tables still match the vendored spec, and
# that every state actually rasterises. A frozen orb that renders blank is a valid, silent PNG.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== generated tables are current"
swift run --quiet OrbsCodegen | diff - Sources/ThinkingOrbsGeometry/Generated/OrbSpec.swift
echo "ok - OrbSpec.swift matches Spec/orbs-spec.json"

echo "== every state, size and scheme rasterises"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT
# The tool itself exits non-zero on a frame with no ink.
swift run --quiet OrbsSnapshot "$OUT" >/dev/null

COUNT=$(find "$OUT" -name '*.png' | wc -l | tr -d ' ')
[ "$COUNT" -eq 36 ] || { echo "not ok - wrote $COUNT frames, expected 36"; exit 1; }
echo "ok - 36 frames"

echo "ok - no frame is blank"
