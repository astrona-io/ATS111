#!/usr/bin/env bash
# PASS when ops-datasources substitutes from platform-vars and checks the Perses Deployment
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

src="$(kubectl -n flux-system get kustomization ops-datasources -o jsonpath='{.spec.postBuild.substituteFrom[*].name}' 2>/dev/null)"
echo "$src" | grep -Fx platform-vars >/dev/null || fail "ops-datasources does not substitute from platform-vars (found: '${src:-none}')."
hc="$(kubectl -n flux-system get kustomization ops-datasources -o jsonpath='{range .spec.healthChecks[*]}{.kind}/{.namespace}/{.name}{"\n"}{end}' 2>/dev/null)"
echo "$hc" | grep -Fx Deployment/perses/perses >/dev/null || fail "ops-datasources has no health check on the Deployment perses in perses."
echo "PASS: substitution from platform-vars and the health check are set."
exit 0
