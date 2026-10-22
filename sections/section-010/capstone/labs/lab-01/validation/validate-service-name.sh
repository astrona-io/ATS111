#!/usr/bin/env bash
# PASS when the Perses server is reachable through the Service perses
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

svc_name="$(kubectl -n perses get perses perses -o jsonpath='{.spec.service.name}')"
[ -z "$svc_name" ] || [ "$svc_name" = "perses" ] || fail "spec.service.name is '$svc_name'. The operator connects to the Service named after the Perses resource, perses."
endpoints="$(kubectl -n perses get endpoints perses -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)"
[ -n "$endpoints" ] || fail "the Service perses has no ready endpoints."
perses_get /api/v1/projects >/dev/null || fail "http://perses.perses:8080 does not answer."
echo "PASS: the Service perses reaches a ready Perses pod."
exit 0
