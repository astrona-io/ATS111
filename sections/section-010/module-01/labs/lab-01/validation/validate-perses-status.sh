#!/usr/bin/env bash
# PASS when the Perses resource is Available and not Degraded
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

available="$(condition_status perses perses perses Available)"
degraded="$(condition_status perses perses perses Degraded)"
[ "$degraded" = "False" ] || fail "the Perses resource perses is Degraded (status: ${degraded:-missing}). Read its conditions."
[ "$available" = "True" ] || fail "the Perses resource perses is not Available (status: ${available:-missing})."
echo "PASS: the Perses resource perses is Available and not Degraded."
exit 0
