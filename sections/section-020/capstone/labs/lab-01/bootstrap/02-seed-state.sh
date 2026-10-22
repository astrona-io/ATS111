#!/usr/bin/env bash
# Creates the starting state for "Fix Dashboards That Never Reach Perses" (`ats-111-capstone-020`).
#
# Applies a Perses resource whose label app.kubernetes.io/instance is only in spec.metadata.labels, and team resources with two more faults: a catalog dashboard panel reference to a missing panel and a catalog datasource URL in the wrong namespace.
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

echo "[lab] Applying the Perses resource and the team resources..."
kubectl apply -f "$MANIFESTS/perses-unlabelled.yaml"
wait_for_perses_server
kubectl apply -f "$MANIFESTS/team-resources.yaml"
uid="$(kubectl -n perses get perses perses -o jsonpath='{.metadata.uid}')"
kubectl -n perses create configmap lab-baseline --from-literal=perses-uid="$uid" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
