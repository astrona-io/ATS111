#!/usr/bin/env bash
# PASS when the Perses resource was fixed in place, not deleted and created again
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

BASELINE="$(kubectl -n perses get configmap lab-baseline -o jsonpath='{.data.perses-uid}' 2>/dev/null)"
CURRENT="$(kubectl -n perses get perses perses -o jsonpath='{.metadata.uid}' 2>/dev/null)"
[ -n "$CURRENT" ] || fail "the Perses resource perses in the namespace perses does not exist."
[ "$BASELINE" = "$CURRENT" ] || fail "the Perses resource perses was deleted and created again. Fix it in place."
echo "PASS: the Perses resource perses is the original object."
exit 0
