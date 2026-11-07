#!/usr/bin/env bash
# Compiles the Foundation-only logic with plain swiftc and runs the shared invariant checks.
# Works on macOS and Linux without Xcode. Usage: ./Tests/run.sh [--rounds N]
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
swiftc \
  Tallhagen/MathLogic.swift \
  Tallhagen/GameSessions.swift \
  Tallhagen/SoundRecipes.swift \
  Tests/SeededGenerator.swift \
  Tests/LogicChecks.swift \
  Tests/main.swift \
  -o "$test_dir/tallhagen-logic-test"
"$test_dir/tallhagen-logic-test" "$@"
