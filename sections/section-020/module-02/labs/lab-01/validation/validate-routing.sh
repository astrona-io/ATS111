#!/usr/bin/env bash
# PASS when staging has the dashboard and the datasource, and production has no checkout dashboard
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

names="$(perses_jq /api/v1/projects/payments/dashboards '.[].metadata.name' staging.perses-staging)" || fail "staging does not list dashboards for the project payments."
echo "$names" | grep -x checkout >/dev/null || fail "staging does not have the dashboard checkout."
perses_jq /api/v1/projects/payments/datasources/prometheus '.metadata.name' staging.perses-staging >/dev/null 2>&1 || fail "staging does not have the datasource prometheus."
prod="$(perses_jq /api/v1/projects/payments/dashboards '.[].metadata.name' perses.perses 2>/dev/null || true)"
echo "$prod" | grep -x checkout >/dev/null && fail "production has the dashboard checkout. It must only be on staging."
echo "PASS: checkout is on staging only."
exit 0
