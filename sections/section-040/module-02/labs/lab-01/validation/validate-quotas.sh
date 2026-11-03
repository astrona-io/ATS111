#!/usr/bin/env bash
# PASS when both quotas exist with the values 2 and 3
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

p="$(kubectl -n payments get resourcequota dashboard-cap -o jsonpath='{.spec.hard.count/persesdashboards\.perses\.dev}' 2>/dev/null)"
[ "$p" = "2" ] || fail "the quota dashboard-cap in payments limits dashboards to '${p:-none}', not 2."
c="$(kubectl -n catalog get resourcequota dashboard-cap -o jsonpath='{.spec.hard.count/persesdashboards\.perses\.dev}' 2>/dev/null)"
[ "$c" = "3" ] || fail "the quota dashboard-cap in catalog limits dashboards to '${c:-none}', not 3."
echo "PASS: the quotas are 2 for payments and 3 for catalog."
exit 0
