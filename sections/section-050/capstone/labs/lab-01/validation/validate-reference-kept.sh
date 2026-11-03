#!/usr/bin/env bash
# PASS when monthly keeps the reference to the panel totals and defines it
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

ref="$(kubectl -n finance get persesdashboard monthly -o jsonpath='{.spec.config.layouts[0].spec.items[0].content.\$ref}' 2>/dev/null)"
[ "$ref" = "#/spec/panels/totals" ] || fail "monthly no longer refers to #/spec/panels/totals (found '$ref')."
kind="$(kubectl -n finance get persesdashboard monthly -o jsonpath='{.spec.config.panels.totals.kind}' 2>/dev/null)"
[ "$kind" = "Panel" ] || fail "monthly does not define the panel totals."
echo "PASS: monthly keeps and defines the panel totals."
exit 0
