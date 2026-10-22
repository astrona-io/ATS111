#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

nudge() {
  # nudge NAMESPACE: changes an annotation on every dashboard and datasource in
  # the namespace. The operator reconciles on any change to the object, so this
  # retries a sync now instead of after the error backoff.
  local stamp
  stamp="$(date +%s)"
  kubectl -n "$1" annotate persesdashboards,persesdatasources --all \
    "astrona.io/retry-at=$stamp" --overwrite >/dev/null 2>&1 || true
}

kubectl -n flux-system patch kustomization catalog-dashboards --type merge -p '{"spec":{"path":"./dashboards/catalog"}}'
kubectl -n flux-system patch kustomization payments-dashboards --type merge -p '{"spec":{"prune":true}}'
git_put "$SCRIPT_DIR/dashboard-latency.yaml" dashboards/payments/dashboard-latency.yaml "Point the latency layout at a panel that exists"
flux reconcile kustomization payments-dashboards --with-source
flux reconcile kustomization catalog-dashboards --with-source
# An object removed from Git while prune was off is no longer in the
# inventory, so Flux does not prune it; delete it by hand.
kubectl -n payments delete persesdashboard payments-legacy --ignore-not-found
nudge payments
for name in payments-latency payments-overview; do
  for _ in $(seq 1 60); do
    [ "$(kubectl -n payments get persesdashboard "$name" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)" = "True" ] && break
    sleep 3
  done
done
