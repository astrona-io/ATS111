#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n observability exec deploy/tester -- curl -fsS -X POST \
  -H 'Content-Type: application/json' \
  -d '{"kind":"Project","metadata":{"name":"ledger"},"spec":{}}' \
  http://perses.perses:8080/api/v1/projects >/dev/null
kubectl -n backups get configmap ledger-backup -o jsonpath='{.data.dashboards\.json}' \
  | kubectl -n observability exec -i deploy/tester -- sh -c \
  'jq -c ".[]" | while read -r d; do curl -fsS -X POST -H "Content-Type: application/json" -d "$d" http://perses.perses:8080/api/v1/projects/ledger/dashboards >/dev/null; done'
kubectl -n observability exec deploy/tester -- \
  curl -fsS http://perses.perses:8080/api/v1/projects/notes/dashboards > /tmp/notes-dashboards.json
kubectl -n backups create configmap notes-backup --from-file=dashboards.json=/tmp/notes-dashboards.json \
  --dry-run=client -o yaml | kubectl apply -f -
