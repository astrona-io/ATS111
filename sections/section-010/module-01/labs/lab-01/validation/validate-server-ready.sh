#!/usr/bin/env bash
# PASS when the Perses server runs v0.54.0 and answers on its API
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

ready="$(kubectl -n perses get deployment perses -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
[ "${ready:-0}" -ge 1 ] 2>/dev/null || fail "the Deployment perses has no ready replica."
image="$(kubectl -n perses get deployment perses -o jsonpath='{.spec.template.spec.containers[0].image}')"
[ "$image" = "docker.io/persesdev/perses:v0.54.0" ] || fail "the Perses server runs $image, not docker.io/persesdev/perses:v0.54.0."
perses_get /api/v1/projects >/dev/null || fail "the Perses API at http://perses.perses:8080 does not answer."
echo "PASS: the Perses server runs v0.54.0 and its API answers."
exit 0
