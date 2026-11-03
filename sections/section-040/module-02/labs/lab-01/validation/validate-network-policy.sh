#!/usr/bin/env bash
# PASS when the NetworkPolicy allows exactly the two namespaces on TCP 8080
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

kubectl -n perses get networkpolicy perses-ingress >/dev/null 2>&1 || fail "the NetworkPolicy perses-ingress does not exist in perses."
sel="$(kubectl -n perses get networkpolicy perses-ingress -o jsonpath='{.spec.podSelector}' 2>/dev/null)"
[ "$sel" = "{}" ] || fail "the policy does not select all pods of the namespace (podSelector: ${sel:-none})."
types="$(kubectl -n perses get networkpolicy perses-ingress -o jsonpath='{.spec.policyTypes[*]}')"
echo "$types" | grep -Fx Ingress >/dev/null || fail "policyTypes does not contain Ingress."
names="$(kubectl -n perses get networkpolicy perses-ingress -o jsonpath='{range .spec.ingress[*].from[*]}{.namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}{"\n"}{end}' | sed '/^$/d' | sort | tr '\n' ' ')"
[ "$names" = "observability perses-operator " ] || fail "the allowed namespaces are '${names}', not observability and perses-operator."
ports="$(kubectl -n perses get networkpolicy perses-ingress -o jsonpath='{range .spec.ingress[*].ports[*]}{.protocol}/{.port}{"\n"}{end}' | sed '/^$/d' | sort -u | tr '\n' ' ')"
[ "$ports" = "TCP/8080 " ] || fail "the allowed ports are '${ports}', not TCP/8080."
echo "PASS: the policy allows observability and perses-operator on TCP 8080."
exit 0
