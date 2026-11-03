#!/usr/bin/env bash
# Creates the starting state for "Restore A Lost Project From A Backup" (`ats-111-lab-050-01`).
#
# Creates the projects ledger and notes through the API, saves a backup of ledger and deletes ledger
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

api_post() {
  # api_post PATH JSON: POST to the Perses API from the tester pod, retrying while the server starts.
  for _ in $(seq 1 30); do
    kubectl -n observability exec deploy/tester -- curl -fsS -X POST -H 'Content-Type: application/json' \
      -d "$2" "http://perses.perses:8080$1" >/dev/null 2>&1 && return 0
    sleep 2
  done
  return 1
}

wait_for_perses_server
kubectl create namespace backups --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Creating the projects ledger and notes..."
api_post /api/v1/projects '{"kind":"Project","metadata":{"name":"ledger"},"spec":{}}'
api_post /api/v1/projects/ledger/dashboards '{"kind":"Dashboard","metadata":{"name":"daily","project":"ledger"},"spec":{"display":{"name":"Daily Ledger"},"duration":"1h","panels":{},"layouts":[]}}'
api_post /api/v1/projects '{"kind":"Project","metadata":{"name":"notes"},"spec":{}}'
api_post /api/v1/projects/notes/dashboards '{"kind":"Dashboard","metadata":{"name":"todo","project":"notes"},"spec":{"display":{"name":"Todo"},"duration":"1h","panels":{},"layouts":[]}}'

echo "[lab] Saving the backup of ledger and deleting the project..."
kubectl -n observability exec deploy/tester -- curl -fsS http://perses.perses:8080/api/v1/projects/ledger/dashboards > /tmp/ledger-dashboards.json
kubectl -n backups create configmap ledger-backup --from-file=dashboards.json=/tmp/ledger-dashboards.json \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n observability exec deploy/tester -- curl -fsS -X DELETE http://perses.perses:8080/api/v1/projects/ledger >/dev/null

echo "[lab] Starting state ready."
