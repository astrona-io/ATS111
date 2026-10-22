#!/usr/bin/env bash
# Creates the starting state for "Keep Each Team In Its Own Namespace" (`ats-111-lab-040-01`).
#
# The task starts from two team namespaces whose ServiceAccounts have no rights at all.
#
# The corrected configuration is NOT applied here; producing it is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

wait_for_perses_server() {
  for _ in $(seq 1 90); do
    kubectl -n perses get deployment perses >/dev/null 2>&1 && break
    sleep 2
  done
  kubectl -n perses rollout status deployment/perses --timeout=300s
}

for team in payments catalog; do
  kubectl -n "$team" get serviceaccount "$team-ci" >/dev/null
done

echo "[lab] Starting state ready."
