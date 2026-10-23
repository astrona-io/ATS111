#!/usr/bin/env bash
# OS prep for "Reconcile Dashboards From Git" (`ats-111-playground-030-01`).
#
# Environment preparation only. There is no task and no grading. It installs
# Helm, percli (and Flux where the module uses it), the Perses Operator, a
# Perses server, Prometheus and the tester pod.
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

WITH_GITOPS="1"            # 1: also Gitea, the repository gitops/fleet and Flux
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
  echo "[playground] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
# percli ships in the Perses release archive, next to the server binary.
have_percli=""
command -v percli >/dev/null 2>&1 && have_percli=$(percli version 2>/dev/null | awk '/[Vv]ersion/{print $NF; exit}' | sed 's/^v//')
if [ "$have_percli" != "$PERSES_VERSION" ]; then
  echo "[playground] Downloading percli ${PERSES_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/perses/perses/releases/download/v${PERSES_VERSION}/perses_${PERSES_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" percli
  install -m 0755 "$WORK/percli" "$BIN_DIR/percli"
fi
if [ "$WITH_GITOPS" = "1" ]; then
  have_flux=""
  command -v flux >/dev/null 2>&1 && have_flux=$(flux version --client 2>/dev/null | awk '/flux:/{print $2}' | sed 's/^v//')
  if [ "$have_flux" != "$FLUX_VERSION" ]; then
    echo "[playground] Downloading Flux CLI ${FLUX_VERSION} (${OS}/${ARCH})..."
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
  echo "[playground] Adding the CoreDNS rewrite for ${host}..."
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

echo "[playground] Starting Prometheus and the tester pod..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n observability rollout status deployment/prometheus --timeout=300s
kubectl -n observability rollout status deployment/tester --timeout=300s

echo "[playground] Installing the Perses Operator (chart ${OPERATOR_CHART_VERSION})..."
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
  echo "[playground] Applying the Perses resource..."
  kubectl apply -f "$MANIFEST_DIR/perses-instance.yaml"
  wait_for_perses_server
fi

GIT_HOST="gitea.localtest.me"
GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
REPO="fleet"

add_coredns_rewrite gitea.localtest.me gitea-http.gitea.svc.cluster.local

echo "[playground] Applying Gitea and its tester pod..."
kubectl apply -f "$MANIFEST_DIR/gitea.yaml"
kubectl -n gitea rollout status deployment/gitea --timeout=300s
kubectl -n gitea rollout status deployment/tester --timeout=300s

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

seed_file() {
  # seed_file LOCAL_FILE REPO_PATH: commits one file to gitops/fleet on main.
  local content
  content="$(base64 < "$1" | tr -d '\n')"
  gitea_api POST "/repos/$GIT_USER/$REPO/contents/$2" \
    "{\"content\":\"$content\",\"message\":\"Add $2\",\"branch\":\"main\"}" >/dev/null
}

echo "[playground] Creating the Gitea user ${GIT_USER} and the repository ${GIT_USER}/${REPO}..."
# Gitea can refuse the first commands while it finishes starting, so retry
# until the user exists; fail here rather than later at the first clone.
gitea_user_ready=false
for _ in $(seq 1 30); do
  kubectl -n gitea exec deploy/gitea -- gitea admin user create \
    --username "$GIT_USER" --password "$GIT_PASSWORD" --email gitops@example.com \
    --admin --must-change-password=false >/dev/null 2>&1 && { gitea_user_ready=true; break; }
  kubectl -n gitea exec deploy/gitea -- gitea admin user list 2>/dev/null \
    | awk 'NR > 1 {print $2}' | grep -x "$GIT_USER" >/dev/null && { gitea_user_ready=true; break; }
  sleep 2
done
[ "$gitea_user_ready" = true ] || { echo "ERROR: could not create the Gitea user $GIT_USER." >&2; exit 1; }
gitea_api GET "/repos/$GIT_USER/$REPO" >/dev/null 2>&1 || \
  gitea_api POST "/user/repos" "{\"name\":\"$REPO\",\"auto_init\":true,\"default_branch\":\"main\",\"private\":true}" >/dev/null

echo "[playground] Seeding the repository with the team dashboards..."
SEED_DIR="$MANIFEST_DIR/repo"
if gitea_api GET "/repos/$GIT_USER/$REPO/contents/dashboards/payments/datasource.yaml" >/dev/null 2>&1; then
  echo "[playground] Repository already seeded."
else
  (cd "$SEED_DIR" && find . -type f | sed 's|^\./||' | sort) | while read -r file; do
    seed_file "$SEED_DIR/$file" "$file"
  done
fi

echo "[playground] Installing the Flux controllers..."
flux install
flux check


echo "[playground] Ready."
kubectl -n perses get perses,deployments,services 2>/dev/null || true
echo "[playground] Perses answers at http://perses.localtest.me:8080 after:"
echo "  kubectl -n perses port-forward svc/perses 8080:8080"
echo "[playground] Gitea answers at http://gitea.localtest.me:3000 after:"
echo "  kubectl -n gitea port-forward svc/gitea-http 3000:3000"
