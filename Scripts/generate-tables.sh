#!/bin/bash
# Regenerates the upstream tables from Spec/orbs-spec.json. Run after re-vendoring the spec;
# Scripts/smoke.sh fails if the checked-in file is stale.
set -euo pipefail
cd "$(dirname "$0")/.."

swift run --quiet OrbsCodegen > Sources/ThinkingOrbsGeometry/Generated/OrbSpec.swift
echo "wrote Sources/ThinkingOrbsGeometry/Generated/OrbSpec.swift"
