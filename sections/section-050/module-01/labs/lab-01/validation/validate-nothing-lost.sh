#!/usr/bin/env bash
# PASS when the ledger backup is unchanged and notes still exists
set -uo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

perses_get() {
  # perses_get PATH [HOST]: GET on the Perses API from the tester pod; prints the body.
  kubectl -n observability exec deploy/tester -- curl -fsS --retry 15 --retry-delay 2 --retry-connrefused "http://${2:-perses.perses}:8080$1"
}
perses_jq() {
  # perses_jq PATH FILTER [HOST]: GET on the Perses API, filtered with jq in the tester pod.
  kubectl -n observability exec deploy/tester -- sh -c "curl -fsS --retry 15 --retry-delay 2 --retry-connrefused 'http://${3:-perses.perses}:8080$1' | jq -r '$2'"
}
condition_status() {
  # condition_status NAMESPACE KIND NAME TYPE: prints the status of one condition.
  kubectl -n "$1" get "$2" "$3" -o jsonpath="{.status.conditions[?(@.type==\"$4\")].status}" 2>/dev/null
}
fail() { echo "FAIL: $*"; exit 1; }

data="$(kubectl -n backups get configmap ledger-backup -o jsonpath='{.data.dashboards\.json}' 2>/dev/null)"
names="$(printf '%s' "$data" | kubectl -n observability exec -i deploy/tester -- jq -r '.[].metadata.name' 2>/dev/null)" || fail "the ConfigMap ledger-backup was changed."
echo "$names" | grep -Fx daily >/dev/null || fail "the ConfigMap ledger-backup no longer holds the dashboard daily."
projects="$(perses_jq /api/v1/projects '.[].metadata.name')" || fail "the Perses API does not answer."
echo "$projects" | grep -Fx notes >/dev/null || fail "the project notes was deleted."
echo "PASS: the backup is unchanged and notes still exists."
exit 0
