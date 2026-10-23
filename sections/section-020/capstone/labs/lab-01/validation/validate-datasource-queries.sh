#!/usr/bin/env bash
# PASS when a query through each team's datasource returns data
set -uo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

perses_get() {
  # perses_get PATH: GET on the Perses API from the tester pod; prints the body.
  kubectl -n observability exec deploy/tester -- curl -fsS --retry 15 --retry-delay 2 --retry-connrefused "http://perses.perses:8080$1"
}
perses_jq() {
  # perses_jq PATH FILTER: GET on the Perses API, filtered with jq in the tester pod.
  kubectl -n observability exec deploy/tester -- sh -c "curl -fsS --retry 15 --retry-delay 2 --retry-connrefused 'http://perses.perses:8080$1' | jq -r '$2'"
}
condition_status() {
  # condition_status NAMESPACE KIND NAME TYPE: prints the status of one condition.
  kubectl -n "$1" get "$2" "$3" -o jsonpath="{.status.conditions[?(@.type==\"$4\")].status}" 2>/dev/null
}
fail() { echo "FAIL: $*"; exit 1; }

result="$(perses_jq '/proxy/projects/payments/datasources/prometheus/api/v1/query?query=up' .status 2>/dev/null)"
[ "$result" = "success" ] || fail "a query through the datasource prometheus of the project payments did not succeed."

result="$(perses_jq '/proxy/projects/catalog/datasources/prometheus/api/v1/query?query=up' .status 2>/dev/null)"
[ "$result" = "success" ] || fail "a query through the datasource prometheus of the project catalog did not succeed."

echo "PASS: queries through the datasources of payments and catalog return data."
exit 0
