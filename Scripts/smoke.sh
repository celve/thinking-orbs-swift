#!/bin/bash
# Checks what `swift test` cannot: that the checked-in generated tables still match what the
# generator produces from the vendored spec. Snapshot rendering joins this once the view exists.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== generated tables are current"
swift run --quiet OrbsCodegen | diff - Sources/ThinkingOrbsGeometry/Generated/OrbSpec.swift
echo "ok - OrbSpec.swift matches Spec/orbs-spec.json"
