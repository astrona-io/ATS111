#!/usr/bin/env bash
# PASS when every team dashboard and datasource is Available and in Perses
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

for kind in persesdatasource/prometheus persesdashboard/payments-overview; do
  status="$(condition_status payments "${kind%%/*}" "${kind##*/}" Available)"
  [ "$status" = "True" ] || fail "$kind in payments is not Available (status: ${status:-missing}). Read its conditions."
done
name="$(perses_jq /api/v1/projects/payments/dashboards/payments-overview .spec.display.name 2>/dev/null)"
[ -n "$name" ] || fail "the Perses API has no dashboard payments-overview in the project payments."
[ "$name" = "Payments Overview" ] || fail "the dashboard payments-overview is named '$name', not 'Payments Overview'."

for kind in persesdatasource/prometheus persesdashboard/catalog-overview; do
  status="$(condition_status catalog "${kind%%/*}" "${kind##*/}" Available)"
  [ "$status" = "True" ] || fail "$kind in catalog is not Available (status: ${status:-missing}). Read its conditions."
done
name="$(perses_jq /api/v1/projects/catalog/dashboards/catalog-overview .spec.display.name 2>/dev/null)"
[ -n "$name" ] || fail "the Perses API has no dashboard catalog-overview in the project catalog."
[ "$name" = "Catalog Overview" ] || fail "the dashboard catalog-overview is named '$name', not 'Catalog Overview'."

echo "PASS: the dashboards and datasources of payments and catalog are Available and in Perses."
exit 0
