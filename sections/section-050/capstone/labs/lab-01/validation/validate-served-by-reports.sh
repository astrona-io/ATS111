#!/usr/bin/env bash
# PASS when the server reports serves both dashboards and perses serves neither
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

names="$(perses_jq /api/v1/projects/finance/dashboards '.[].metadata.name' reports.reports)" || fail "the server reports does not answer for the project finance."
echo "$names" | grep -Fx weekly >/dev/null || fail "the server reports does not serve weekly."
echo "$names" | grep -Fx monthly >/dev/null || fail "the server reports does not serve monthly."
other="$(perses_jq /api/v1/projects/finance/dashboards '.[].metadata.name' perses.perses 2>/dev/null || true)"
echo "$other" | grep -E '^(weekly|monthly)$' >/dev/null && fail "the server perses also has a finance dashboard."
echo "PASS: reports serves both dashboards and perses neither."
exit 0
