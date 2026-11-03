#!/usr/bin/env bash
# PASS when the dashboard payments-ops is Available and served by Perses
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

[ "$(condition_status payments persesdashboard payments-ops Available)" = "True" ] || fail "the dashboard payments-ops is not Available."
names="$(perses_jq /api/v1/projects/payments/dashboards '.[].metadata.name')" || fail "the Perses API does not answer."
echo "$names" | grep -Fx payments-ops >/dev/null || fail "Perses does not serve the dashboard payments-ops."
echo "PASS: Perses serves the dashboard payments-ops."
exit 0
