#!/usr/bin/env bash
# PASS when the Perses server has enough memory and stays ready
set -uo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

perses_get() {
  # perses_get PATH: GET on the Perses API from the tester pod; prints the body.
  kubectl -n observability exec deploy/tester -- curl -fsS "http://perses.perses:8080$1"
}
perses_jq() {
  # perses_jq PATH FILTER: GET on the Perses API, filtered with jq in the tester pod.
  kubectl -n observability exec deploy/tester -- sh -c "curl -fsS 'http://perses.perses:8080$1' | jq -r '$2'"
}
condition_status() {
  # condition_status NAMESPACE KIND NAME TYPE: prints the status of one condition.
  kubectl -n "$1" get "$2" "$3" -o jsonpath="{.status.conditions[?(@.type==\"$4\")].status}" 2>/dev/null
}
fail() { echo "FAIL: $*"; exit 1; }

limit="$(kubectl -n perses get deployment perses -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')"
case "$limit" in
  "") ;;
  *Gi) ;;
  *Mi) [ "${limit%Mi}" -ge 128 ] || fail "the memory limit $limit is too low for the Perses server; give it at least 128Mi." ;;
  *) fail "the memory limit '$limit' is not in Mi or Gi." ;;
esac
ready="$(kubectl -n perses get deployment perses -o jsonpath='{.status.readyReplicas}')"
[ "${ready:-0}" -ge 1 ] 2>/dev/null || fail "the Deployment perses has no ready replica."
reason="$(kubectl -n perses get pods -l app.kubernetes.io/instance=perses -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}')"
case "$reason" in *CrashLoopBackOff*) fail "a Perses pod is in CrashLoopBackOff." ;; esac
echo "PASS: the Perses server is ready with a memory limit of ${limit:-none}."
exit 0
