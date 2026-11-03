#!/usr/bin/env bash
# PASS when the source fleet and both Kustomizations are Ready
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

[ "$(condition_status flux-system gitrepository fleet Ready)" = "True" ] || fail "the GitRepository fleet is not Ready."
[ "$(condition_status flux-system kustomization ops-datasources Ready)" = "True" ] || fail "the Kustomization ops-datasources is not Ready."
[ "$(condition_status flux-system kustomization ops-dashboards Ready)" = "True" ] || fail "the Kustomization ops-dashboards is not Ready."
echo "PASS: the source and both Kustomizations are Ready."
exit 0
