#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# `astrona test` bootstraps and applies in one go. Wait until the operator and
# the Perses server answer and Flux passes its checks, so the reference solution is not
# applied into a half-started environment.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n perses-operator wait deployment --all --for=condition=Available --timeout=300s
for _ in $(seq 1 90); do
  kubectl -n perses get deployment perses >/dev/null 2>&1 && break
  sleep 2
done
kubectl -n perses rollout status deployment/perses --timeout=300s
for _ in $(seq 1 60); do
  kubectl -n observability exec deploy/tester -- curl -fsS http://perses.perses:8080/api/v1/projects >/dev/null 2>&1 && break
  sleep 3
done
kubectl -n gitea rollout status deployment/gitea --timeout=300s
for _ in $(seq 1 60); do
  flux check >/dev/null 2>&1 && exit 0
  sleep 3
done
echo "Flux did not pass flux check in time." >&2
exit 1
