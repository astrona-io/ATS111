#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$SCRIPT_DIR/limits.yaml"
for _ in $(seq 1 30); do
  used="$(kubectl -n payments get resourcequota dashboard-cap -o jsonpath='{.status.used.count/persesdashboards\.perses\.dev}' 2>/dev/null)"
  [ "$used" = "1" ] && break
  sleep 2
done
