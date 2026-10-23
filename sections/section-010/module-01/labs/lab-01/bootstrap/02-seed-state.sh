#!/usr/bin/env bash
# Creates the starting state for "Fix A Perses Server That Never Serves" (`ats-111-lab-010-01`).
#
# Applies a Perses resource with two faults: the image tag has no leading v, and a volumeMount names a volume that spec.volumes does not define.
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

echo "[lab] Applying the ConfigMap perses-extra and the Perses resource..."
kubectl apply -f "$MANIFESTS/perses-extra.yaml"
kubectl apply -f "$MANIFESTS/broken-perses.yaml"
for _ in $(seq 1 60); do
  kubectl -n perses get perses perses -o jsonpath='{.status.conditions[*].type}' 2>/dev/null | grep -q Degraded && break
  sleep 2
done
uid="$(kubectl -n perses get perses perses -o jsonpath='{.metadata.uid}')"
kubectl -n perses create configmap lab-baseline --from-literal=perses-uid="$uid" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
