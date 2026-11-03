#!/usr/bin/env bash
# Creates the starting state for "Send A Dashboard To Staging And Limit Its Datasource" (`ats-111-lab-020-02`).
#
# Starts the second Perses server staging (label env=staging) and leaves production unlabelled
#
# The corrected configuration is NOT applied here; producing it is the task.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

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

wait_for_staging() {
  for _ in $(seq 1 90); do
    kubectl -n perses-staging get deployment staging >/dev/null 2>&1 && break
    sleep 2
  done
  kubectl -n perses-staging rollout status deployment/staging --timeout=300s
}

echo "[lab] Starting the staging server..."
kubectl apply -f "$MANIFESTS/perses-staging.yaml"
wait_for_staging

echo "[lab] Starting state ready."
