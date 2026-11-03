#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$SCRIPT_DIR/fixed.yaml"
kubectl -n reports rollout status deployment/reports --timeout=300s
for _ in $(seq 1 60); do
  a="$(kubectl -n finance get persesdashboard weekly -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)"
  b="$(kubectl -n finance get persesdashboard monthly -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)"
  [ "$a" = "True" ] && [ "$b" = "True" ] && break
  sleep 3
done
