#!/usr/bin/env bash
# PASS when the GitRepository and both team Flux Kustomizations are Ready and prune
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

[ "$(condition_status flux-system gitrepository fleet Ready)" = "True" ] || fail "the GitRepository fleet in flux-system is not Ready."
for team in payments catalog; do
  name="$team-dashboards"
  [ "$(condition_status flux-system kustomization "$name" Ready)" = "True" ] || fail "the Flux Kustomization $name is not Ready."
  path="$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.spec.path}')"
  case "$path" in ./dashboards/$team|dashboards/$team|./dashboards/$team/) ;; *) fail "$name applies '$path', not ./dashboards/$team." ;; esac
  [ "$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.spec.prune}')" = "true" ] || fail "$name must prune."
done
echo "PASS: the source and both team Kustomizations are Ready and prune."
exit 0
