#!/usr/bin/env bash
# PASS when the extra volume is mounted from the ConfigMap perses-extra
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

mount="$(kubectl -n perses get perses perses -o jsonpath='{.spec.volumeMounts[?(@.name=="extra")].mountPath}')"
[ "$mount" = "/etc/perses/extra" ] || fail "the volumeMount extra at /etc/perses/extra must stay on the Perses resource."
source_cm="$(kubectl -n perses get perses perses -o jsonpath='{.spec.volumes[?(@.name=="extra")].configMap.name}')"
[ "$source_cm" = "perses-extra" ] || fail "spec.volumes must define the volume extra from the ConfigMap perses-extra."
pod_cm="$(kubectl -n perses get deployment perses -o jsonpath='{.spec.template.spec.volumes[?(@.name=="extra")].configMap.name}')"
[ "$pod_cm" = "perses-extra" ] || fail "the Deployment perses does not mount the ConfigMap perses-extra yet."
echo "PASS: the volume extra comes from the ConfigMap perses-extra and is mounted."
exit 0
