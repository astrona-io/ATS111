#!/usr/bin/env bash
# PASS when ops-dashboards depends on ops-datasources and both prune
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

dep="$(kubectl -n flux-system get kustomization ops-dashboards -o jsonpath='{.spec.dependsOn[*].name}' 2>/dev/null)"
echo "$dep" | grep -Fx ops-datasources >/dev/null || fail "ops-dashboards does not depend on ops-datasources (dependsOn: '${dep:-none}')."
for k in ops-datasources ops-dashboards; do
  [ "$(kubectl -n flux-system get kustomization $k -o jsonpath='{.spec.prune}' 2>/dev/null)" = "true" ] || fail "$k does not prune."
done
[ "$(kubectl -n flux-system get kustomization ops-datasources -o jsonpath='{.spec.path}')" = "./ops/datasources" ] || fail "ops-datasources does not use ./ops/datasources."
[ "$(kubectl -n flux-system get kustomization ops-dashboards -o jsonpath='{.spec.path}')" = "./ops/dashboards" ] || fail "ops-dashboards does not use ./ops/dashboards."
echo "PASS: the dependency, the paths and pruning are set."
exit 0
