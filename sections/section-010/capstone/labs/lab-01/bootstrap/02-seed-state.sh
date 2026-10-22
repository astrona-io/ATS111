#!/usr/bin/env bash
# Creates the starting state for "Make The Operator Reach Its Perses Server" (`ats-111-capstone-010`).
#
# Applies a Perses resource whose Service is renamed to perses-ui (the operator still connects to perses) and whose memory limit is 16Mi, plus the payments datasource and dashboard.
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

echo "[lab] Applying the Perses resource and the payments resources..."
kubectl apply -f "$MANIFESTS/broken-perses.yaml"
for _ in $(seq 1 90); do
  kubectl -n perses get deployment perses >/dev/null 2>&1 && break
  sleep 2
done
kubectl apply -f "$MANIFESTS/payments-resources.yaml"
uid="$(kubectl -n perses get perses perses -o jsonpath='{.metadata.uid}')"
kubectl -n perses create configmap lab-baseline --from-literal=perses-uid="$uid" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
