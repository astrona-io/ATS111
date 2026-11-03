#!/usr/bin/env bash
# PASS when the datasource ops-prometheus is Available with the address from the ConfigMap
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

[ "$(condition_status payments persesdatasource ops-prometheus Available)" = "True" ] || fail "the datasource ops-prometheus in payments is not Available."
url="$(kubectl -n payments get persesdatasource ops-prometheus -o jsonpath='{.spec.config.plugin.spec.proxy.spec.url}' 2>/dev/null)"
want="$(kubectl -n flux-system get configmap platform-vars -o jsonpath='{.data.PROMETHEUS_URL}' 2>/dev/null)"
[ -n "$want" ] || fail "the ConfigMap platform-vars has no PROMETHEUS_URL."
[ "$url" = "$want" ] || fail "the datasource address is '$url', not '$want'."
echo "PASS: the datasource uses the address from the ConfigMap."
exit 0
