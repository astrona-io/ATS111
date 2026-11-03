#!/usr/bin/env bash
# PASS when a new dashboard becomes Available after the policy exists
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
for _ in $(seq 1 30); do
  used="$(kubectl -n payments get resourcequota dashboard-cap -o jsonpath='{.status.used.count/persesdashboards\.perses\.dev}' 2>/dev/null)"
  [ "$used" = "1" ] && break
  sleep 2
done
extra_dashboard grade-one >/dev/null || fail "could not create a test dashboard in payments."
ok=0
for _ in $(seq 1 40); do
  [ "$(condition_status payments persesdashboard grade-one Available)" = "True" ] && { ok=1; break; }
  sleep 3
done
[ "$ok" = 1 ] || fail "the test dashboard did not become Available. Does the policy allow the operator?"
names="$(perses_jq /api/v1/projects/payments/dashboards '.[].metadata.name')" || fail "the Perses API does not answer from the tester pod."
echo "$names" | grep -Fx grade-one >/dev/null || fail "Perses does not serve the test dashboard."
echo "PASS: the operator still delivers dashboards to the server."
exit 0
