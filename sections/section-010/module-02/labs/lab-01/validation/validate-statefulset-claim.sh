#!/usr/bin/env bash
# PASS when the operator created a StatefulSet and a bound claim of 1Gi, and no Deployment
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

kubectl -n archive get statefulset archive >/dev/null 2>&1 || fail "the StatefulSet archive does not exist."
kubectl -n archive get deployment archive >/dev/null 2>&1 && fail "a Deployment archive exists. A file database on a claim runs in a StatefulSet."
phase="$(kubectl -n archive get pvc -o jsonpath='{.items[0].status.phase}' 2>/dev/null)"
[ "$phase" = "Bound" ] || fail "the PersistentVolumeClaim is not Bound (phase: ${phase:-none})."
size="$(kubectl -n archive get pvc -o jsonpath='{.items[0].spec.resources.requests.storage}')"
[ "$size" = "1Gi" ] || fail "the claim requests $size, not 1Gi."
echo "PASS: StatefulSet archive with a bound claim of 1Gi."
exit 0
