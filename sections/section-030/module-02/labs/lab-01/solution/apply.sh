#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$SCRIPT_DIR/flux-ops.yaml"
flux reconcile source git fleet || true
flux reconcile kustomization ops-datasources --with-source || true
for _ in $(seq 1 60); do
  [ "$(kubectl -n flux-system get kustomization ops-datasources -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = "True" ] && break
  sleep 3
done
flux reconcile kustomization ops-dashboards || true
for _ in $(seq 1 60); do
  [ "$(kubectl -n payments get persesdashboard payments-ops -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)" = "True" ] && break
  sleep 3
done
