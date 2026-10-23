#!/usr/bin/env bash
# PASS when each team's dashboard is in Perses and the cross-namespace dashboard is gone
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

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

GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
REPO="fleet"
gitea_api() {
  # gitea_api METHOD PATH [JSON]: calls the Gitea API from the tester pod in gitea.
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | kubectl -n gitea exec -i deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" -H 'Content-Type: application/json' \
      --data-binary @- "http://gitea-http.gitea:3000/api/v1$path"
  else
    kubectl -n gitea exec deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" "http://gitea-http.gitea:3000/api/v1$path"
  fi
}
git_raw() {
  # git_raw PATH: prints a file from gitops/fleet on main, or nothing if it does not exist.
  kubectl -n gitea exec deploy/tester -- \
    curl -fsS -u "$GIT_USER:$GIT_PASSWORD" "http://gitea-http.gitea:3000/api/v1/repos/$GIT_USER/$REPO/raw/$1?ref=main" 2>/dev/null || true
}
git_sha() {
  # git_sha PATH: prints the blob SHA Gitea needs to update or delete a file.
  gitea_api GET "/repos/$GIT_USER/$REPO/contents/$1?ref=main" \
    | sed -n 's/.*"sha":"\([0-9a-f]*\)".*/\1/p' | head -1
}
git_put() {
  # git_put LOCAL_FILE REPO_PATH MESSAGE: replaces one file in gitops/fleet on main.
  local content sha
  content="$(base64 < "$1" | tr -d '\n')"
  sha="$(git_sha "$2")"
  gitea_api PUT "/repos/$GIT_USER/$REPO/contents/$2" \
    "{\"content\":\"$content\",\"sha\":\"$sha\",\"message\":\"$3\",\"branch\":\"main\"}" >/dev/null
}
git_delete() {
  # git_delete REPO_PATH MESSAGE: deletes one file from gitops/fleet on main.
  local sha
  sha="$(git_sha "$1")"
  [ -n "$sha" ] || return 0
  gitea_api DELETE "/repos/$GIT_USER/$REPO/contents/$1" \
    "{\"sha\":\"$sha\",\"message\":\"$2\",\"branch\":\"main\"}" >/dev/null
}

kubectl -n payments get persesdashboard payments-takeover >/dev/null 2>&1 && fail "the PersesDashboard payments-takeover still exists in payments."
git_raw dashboards/catalog/payments-takeover.yaml | grep -q 'namespace: payments' && fail "the catalog folder in Git still holds a dashboard for the payments namespace."
code="$(kubectl -n observability exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}' http://perses.perses:8080/api/v1/projects/payments/dashboards/payments-takeover)"
[ "$code" = "404" ] || fail "Perses still serves payments/payments-takeover (HTTP $code)."

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
