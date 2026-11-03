#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$SCRIPT_DIR/perses-archive.yaml"
for _ in $(seq 1 90); do
  kubectl -n archive get statefulset archive >/dev/null 2>&1 && break
  sleep 2
done
kubectl -n archive rollout status statefulset/archive --timeout=300s
for _ in $(seq 1 30); do
  kubectl -n observability exec deploy/tester -- curl -fsS -X POST \
    -H 'Content-Type: application/json' \
    -d '{"kind":"Project","metadata":{"name":"records"},"spec":{}}' \
    http://archive.archive:8080/api/v1/projects >/dev/null 2>&1 && break
  sleep 2
done
