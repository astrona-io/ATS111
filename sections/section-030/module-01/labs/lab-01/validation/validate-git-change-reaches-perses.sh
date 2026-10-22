#!/usr/bin/env bash
# PASS when a change pushed to Git reaches the Perses API
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

stamp="graded-$(date +%s)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git_raw dashboards/payments/dashboard-overview.yaml > "$work/original.yaml"
[ -s "$work/original.yaml" ] || fail "dashboards/payments/dashboard-overview.yaml is missing from gitops/fleet."
sed "s/^      name: Payments Overview.*/      name: Payments Overview $stamp/" "$work/original.yaml" > "$work/changed.yaml"
grep -q "$stamp" "$work/changed.yaml" || fail "the grader could not find the display name line 'name: Payments Overview' in the dashboard file."
git_put "$work/changed.yaml" dashboards/payments/dashboard-overview.yaml "grader: rename the payments dashboard"
flux reconcile kustomization payments-dashboards --with-source >/dev/null 2>&1 || true
for _ in $(seq 1 40); do
  name="$(perses_jq /api/v1/projects/payments/dashboards/payments-overview .spec.display.name 2>/dev/null)"
  if [ "$name" = "Payments Overview $stamp" ]; then
    git_put "$work/original.yaml" dashboards/payments/dashboard-overview.yaml "grader: restore the payments dashboard"
    flux reconcile kustomization payments-dashboards --with-source >/dev/null 2>&1 || true
    echo "PASS: a change pushed to Git reached the Perses API."
    exit 0
  fi
  sleep 3
done
git_put "$work/original.yaml" dashboards/payments/dashboard-overview.yaml "grader: restore the payments dashboard"
fail "the new display name did not reach Perses within two minutes."
