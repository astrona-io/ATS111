#!/usr/bin/env bash
# PASS when the project records is on the server and survives the deletion of the pod
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

names="$(perses_jq /api/v1/projects '.[].metadata.name' archive.archive)" || fail "the Perses API at http://archive.archive:8080 does not answer."
echo "$names" | grep -x records >/dev/null || fail "the project records does not exist."
kubectl -n archive delete pod archive-0 --wait=true >/dev/null 2>&1 || fail "could not delete the pod archive-0."
kubectl -n archive rollout status statefulset/archive --timeout=300s >/dev/null 2>&1 || fail "the StatefulSet archive did not become ready again."
names="$(perses_jq /api/v1/projects '.[].metadata.name' archive.archive)" || fail "the Perses API does not answer after the restart."
echo "$names" | grep -x records >/dev/null || fail "the project records is gone after the pod was deleted."
echo "PASS: the project records survived the deletion of the pod."
exit 0
