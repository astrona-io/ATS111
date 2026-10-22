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

kubectl -n perses label perses perses app.kubernetes.io/instance=perses --overwrite
kubectl -n catalog patch persesdatasource prometheus --type merge \
  -p '{"spec":{"config":{"plugin":{"spec":{"proxy":{"spec":{"url":"http://prometheus.observability.svc.cluster.local:9090"}}}}}}}'
kubectl -n catalog patch persesdashboard catalog-overview --type json \
  -p '[{"op":"replace","path":"/spec/config/layouts/0/spec/items/0/content/$ref","value":"#/spec/panels/up"}]'
nudge payments
nudge catalog
for team in payments catalog; do
  for _ in $(seq 1 60); do
    [ "$(kubectl -n "$team" get persesdashboard "$team-overview" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)" = "True" ] && break
    sleep 3
  done
done
