#!/usr/bin/env bash
# PASS when the Perses resource reports is Available, not Degraded, and uses the right image
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

[ "$(condition_status reports perses reports Available)" = "True" ] || fail "the Perses resource reports is not Available."
[ "$(condition_status reports perses reports Degraded)" != "True" ] || fail "the Perses resource reports is Degraded."
img="$(kubectl -n reports get perses reports -o jsonpath='{.spec.image}' 2>/dev/null)"
[ "$img" = "docker.io/persesdev/perses:v0.54.0" ] || fail "the image is '$img'."
echo "PASS: the server reports is Available on the right image."
exit 0
