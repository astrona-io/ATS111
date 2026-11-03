#!/usr/bin/env bash
# PASS when the datasource lists exactly the five required paths
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

patterns="$(perses_jq /api/v1/projects/payments/datasources/prometheus '.spec.plugin.spec.proxy.spec.allowedEndpoints[].endpointPattern' staging.perses-staging 2>/dev/null)" || fail "could not read the datasource prometheus from staging."
count="$(echo "$patterns" | sed '/^$/d' | wc -l | tr -d ' ')"
[ "$count" = "5" ] || fail "the datasource lists $count paths, not 5."
for p in '/api/v1/query' '/api/v1/query_range' '/api/v1/labels' '/api/v1/label/([a-zA-Z0-9_-]+)/values' '/api/v1/series'; do
  echo "$patterns" | grep -Fx -- "$p" >/dev/null || fail "the path $p is not in the list."
done
echo "PASS: the datasource allows exactly the five required paths."
exit 0
