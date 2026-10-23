#!/usr/bin/env bash
# Creates the starting state for "Deliver Dashboards From Git With Flux" (`ats-111-lab-030-01`).
#
# The task starts from a seeded repository and no Flux objects.
#
# The corrected configuration is NOT applied here; producing it is the task.
set -euo pipefail
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

wait_for_perses_server() {
  for _ in $(seq 1 90); do
    kubectl -n perses get deployment perses >/dev/null 2>&1 && break
    sleep 2
  done
  kubectl -n perses rollout status deployment/perses --timeout=300s
}

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

git_raw dashboards/payments/dashboard-overview.yaml | grep -q payments-overview
git_raw dashboards/catalog/dashboard-overview.yaml | grep -q catalog-overview

echo "[lab] Starting state ready."
