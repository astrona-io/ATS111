#!/usr/bin/env bash
# PASS when every resource still selects the Perses server by label
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

for kind in persesdatasource/prometheus persesdashboard/payments-overview; do
  value="$(kubectl -n payments get "$kind" -o jsonpath='{.spec.instanceSelector.matchLabels.app\.kubernetes\.io/instance}' 2>/dev/null)"
  [ "$value" = "perses" ] || fail "$kind in payments must keep instanceSelector app.kubernetes.io/instance: perses."
done

for kind in persesdatasource/prometheus persesdashboard/catalog-overview; do
  value="$(kubectl -n catalog get "$kind" -o jsonpath='{.spec.instanceSelector.matchLabels.app\.kubernetes\.io/instance}' 2>/dev/null)"
  [ "$value" = "perses" ] || fail "$kind in catalog must keep instanceSelector app.kubernetes.io/instance: perses."
done

echo "PASS: every dashboard and datasource still selects the Perses server by label."
exit 0
