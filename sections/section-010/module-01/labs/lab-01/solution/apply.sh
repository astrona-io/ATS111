#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

nudge() {
  # nudge NAMESPACE: changes an annotation on every dashboard and datasource in
  # the namespace. The operator reconciles on any change to the object, so this
  # retries a sync now instead of after the error backoff.
  local stamp
  stamp="$(date +%s)"
  kubectl -n "$1" annotate persesdashboards,persesdatasources --all \
    "astrona.io/retry-at=$stamp" --overwrite >/dev/null 2>&1 || true
}

kubectl -n perses patch perses perses --type merge -p '{
  "spec": {
    "image": "docker.io/persesdev/perses:v0.54.0",
    "volumes": [{"name": "extra", "configMap": {"name": "perses-extra"}}]
  }
}'
for _ in $(seq 1 90); do
  kubectl -n perses get deployment perses >/dev/null 2>&1 && break
  sleep 2
done
kubectl -n perses rollout status deployment/perses --timeout=300s
