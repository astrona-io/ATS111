#!/usr/bin/env bash
# PASS when the ConfigMap notes-backup holds the dashboard todo
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

data="$(kubectl -n backups get configmap notes-backup -o jsonpath='{.data.dashboards\.json}' 2>/dev/null)"
[ -n "$data" ] || fail "the ConfigMap notes-backup has no key dashboards.json."
names="$(printf '%s' "$data" | kubectl -n observability exec -i deploy/tester -- jq -r '.[].metadata.name' 2>/dev/null)" || fail "the value of dashboards.json is not a JSON list of dashboards."
echo "$names" | grep -Fx todo >/dev/null || fail "the backup does not contain the dashboard todo."
echo "PASS: the backup of notes holds the dashboard todo."
exit 0
