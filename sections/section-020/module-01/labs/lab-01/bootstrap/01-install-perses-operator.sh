#!/usr/bin/env bash
# Installs the tools and the Perses Operator for "Give Two Teams Their Own Dashboards" (`ats-111-lab-020-01`).
#
# Graded lab bootstrap: this prepares the environment ONLY. The starting state
# the task works from is created by 02-seed-state.sh.
set -euo pipefail

WITH_GITOPS="0"            # 1: also Gitea, the repository gitops/fleet and Flux
APPLY_PERSES="1"           # 1: apply manifests/perses-instance.yaml
TEAM_NAMESPACES="payments catalog"
TEAM_SERVICE_ACCOUNTS="0"   # 1: one ServiceAccount <team>-ci per team namespace

HELM_VERSION="3.22.1"
PERSES_VERSION="0.54.0"
OPERATOR_CHART_VERSION="0.5.0"
FLUX_VERSION="2.9.6"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Pin the tools rather than accepting whatever is on the machine.
have_helm=""
command -v helm >/dev/null 2>&1 && have_helm=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_helm" != "$HELM_VERSION" ]; then
  echo "[lab] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
# percli ships in the Perses release archive, next to the server binary.
have_percli=""
command -v percli >/dev/null 2>&1 && have_percli=$(percli version 2>/dev/null | awk '/[Vv]ersion/{print $NF; exit}' | sed 's/^v//')
if [ "$have_percli" != "$PERSES_VERSION" ]; then
  echo "[lab] Downloading percli ${PERSES_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/perses/perses/releases/download/v${PERSES_VERSION}/perses_${PERSES_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" percli
  install -m 0755 "$WORK/percli" "$BIN_DIR/percli"
fi
if [ "$WITH_GITOPS" = "1" ]; then
  have_flux=""
  command -v flux >/dev/null 2>&1 && have_flux=$(flux version --client 2>/dev/null | awk '/flux:/{print $2}' | sed 's/^v//')
  if [ "$have_flux" != "$FLUX_VERSION" ]; then
    echo "[lab] Downloading Flux CLI ${FLUX_VERSION} (${OS}/${ARCH})..."
    curl -fsSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_${OS}_${ARCH}.tar.gz" \
      | tar -xz -C "$WORK" flux
    install -m 0755 "$WORK/flux" "$BIN_DIR/flux"
  fi
fi
helm version --short

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

add_coredns_rewrite() {
  # add_coredns_rewrite HOST TARGET: adds one CoreDNS `rewrite stop` block that
  # sends HOST to TARGET inside the cluster. The answer name is rewritten back
  # to HOST: Go programs ignore DNS answers whose name differs from the
  # question. Runs once per HOST.
  local host="$1" target="$2" corefile host_re target_re
  corefile="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}')"
  if printf '%s\n' "$corefile" | grep -qF "$host"; then return 0; fi
  echo "[lab] Adding the CoreDNS rewrite for ${host}..."
  host_re="$(printf '%s' "$host" | sed 's/\./\\\\./g')"
  target_re="$(printf '%s' "$target" | sed 's/\./\\\\./g')"
  corefile="$(printf '%s\n' "$corefile" | awk -v host="$host" -v target="$target" \
      -v host_re="$host_re" -v target_re="$target_re" '
    /^[[:space:]]*kubernetes / && !done {
      print "    rewrite stop {"
      print "        name regex " host_re " " target
      print "        answer name " target_re " " host
      print "    }"
      done=1
    } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$corefile" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
}

wait_for_perses_server() {
  # The operator creates the Deployment `perses` a few seconds after the
  # Perses object is applied; wait for it to exist, then for it to be ready.
  for _ in $(seq 1 90); do
    kubectl -n perses get deployment perses >/dev/null 2>&1 && break
    sleep 2
  done
  kubectl -n perses rollout status deployment/perses --timeout=300s
}

add_coredns_rewrite perses.localtest.me perses.perses.svc.cluster.local

echo "[lab] Starting Prometheus and the tester pod..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n observability rollout status deployment/prometheus --timeout=300s
kubectl -n observability rollout status deployment/tester --timeout=300s

echo "[lab] Installing the Perses Operator (chart ${OPERATOR_CHART_VERSION})..."
helm repo add perses https://perses.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update perses >/dev/null
# Without cert-manager the chart generates its own webhook certificate; only
# v1alpha2 resources can be used then, which is all this course uses.
helm upgrade --install perses-operator perses/perses-operator --version "$OPERATOR_CHART_VERSION" \
  --namespace perses-operator --create-namespace \
  --set certManager.enable=false \
  --set testFramework.enabled=false \
  --wait --timeout 10m
kubectl wait --for condition=Established --timeout=120s \
  crd/perses.perses.dev crd/persesdashboards.perses.dev \
  crd/persesdatasources.perses.dev crd/persesglobaldatasources.perses.dev

for team in $TEAM_NAMESPACES; do
  kubectl create namespace "$team" --dry-run=client -o yaml | kubectl apply -f -
  if [ "$TEAM_SERVICE_ACCOUNTS" = "1" ]; then
    kubectl -n "$team" create serviceaccount "${team}-ci" --dry-run=client -o yaml | kubectl apply -f -
  fi
done

if [ "$APPLY_PERSES" = "1" ]; then
  echo "[lab] Applying the Perses resource..."
  kubectl apply -f "$MANIFEST_DIR/perses-instance.yaml"
  wait_for_perses_server
fi

echo "[lab] Environment ready."
