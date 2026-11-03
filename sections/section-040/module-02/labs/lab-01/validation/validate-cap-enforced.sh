#!/usr/bin/env bash
# PASS when a second dashboard fits in payments and a third is refused
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

extra_dashboard() {
  # extra_dashboard NAME: applies a small dashboard in payments and prints kubectl's output.
  kubectl -n payments apply -f - 2>&1 <<EOT
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: $1
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: $1
    duration: 1h
    panels: {}
    layouts: []
EOT
}
cleanup() { kubectl -n payments delete persesdashboard grade-one grade-two --ignore-not-found >/dev/null 2>&1; }
trap cleanup EXIT
kubectl -n payments get persesdashboard payments-overview >/dev/null 2>&1 || fail "the existing dashboard payments-overview was deleted."
for _ in $(seq 1 30); do
  used="$(kubectl -n payments get resourcequota dashboard-cap -o jsonpath='{.status.used.count/persesdashboards\.perses\.dev}' 2>/dev/null)"
  [ "$used" = "1" ] && break
  sleep 2
done
[ "$used" = "1" ] || fail "the quota reports $used dashboards in use, not 1."
out="$(extra_dashboard grade-one)" || fail "a second dashboard was refused although the cap is 2: $out"
out="$(extra_dashboard grade-two)" && fail "a third dashboard was accepted. The cap is not enforced."
echo "$out" | grep -F "exceeded quota" >/dev/null || fail "the third dashboard was refused, but not by the quota: $out"
echo "PASS: the second dashboard fits and the third is refused by the quota."
exit 0
