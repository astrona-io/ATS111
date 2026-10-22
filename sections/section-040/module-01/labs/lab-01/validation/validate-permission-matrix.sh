#!/usr/bin/env bash
# PASS when each team can edit Perses resources in its own namespace only
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

can() { kubectl auth can-i "$1" "$2" -n "$3" --as "system:serviceaccount:$4:$4-ci" 2>/dev/null; }
for team in payments catalog; do
  other=catalog; [ "$team" = catalog ] && other=payments
  [ "$(can create persesdashboards.perses.dev "$team" "$team")" = "yes" ] || fail "$team-ci cannot create PersesDashboards in $team."
  [ "$(can create persesdatasources.perses.dev "$team" "$team")" = "yes" ] || fail "$team-ci cannot create PersesDatasources in $team."
  [ "$(can create persesdashboards.perses.dev "$other" "$team")" = "no" ] || fail "$team-ci can create PersesDashboards in $other."
  [ "$(can create rolebindings.rbac.authorization.k8s.io "$team" "$team")" = "no" ] || fail "$team-ci can create RoleBindings in $team; it could give itself more rights."
  [ "$(kubectl auth can-i create persesglobaldatasources.perses.dev --as "system:serviceaccount:$team:$team-ci" 2>/dev/null)" = "no" ] \
    || fail "$team-ci can create PersesGlobalDatasources, which every project sees."
  [ "$(can create perses.perses.dev perses "$team")" = "no" ] || fail "$team-ci can create Perses servers."
done
echo "PASS: each team can edit Perses resources in its own namespace and nowhere else."
exit 0
