# Solution: Deliver Dashboards From Git With Flux

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the Flux objects, the dashboards applied by Flux and served by Perses, and a change pushed to Git that reaches Perses.

## Step 1: Give Flux the credentials

The repository is private. Create the Secret in the format source-controller expects:

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
```

The Secret lands in `flux-system`, the Flux CLI's default namespace. The Gitea server uses plain HTTP and lab-only credentials; a real server uses HTTPS or SSH.

## Step 2: Declare the source and the two syncs

Save this as `flux-dashboards.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: fleet
  namespace: flux-system
spec:
  interval: 1m
  url: http://gitea.localtest.me:3000/gitops/fleet.git
  ref:
    branch: main
  secretRef:
    name: fleet-auth
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: payments-dashboards
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./dashboards/payments
  prune: true
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: catalog-dashboards
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./dashboards/catalog
  prune: true
```

Apply it:

```sh
kubectl apply -f flux-dashboards.yaml
```

## Step 3: Check Flux, then the operator

```sh
flux reconcile kustomization payments-dashboards --with-source
flux reconcile kustomization catalog-dashboards
flux get kustomizations
for team in payments catalog; do
  kubectl -n "$team" get persesdashboard "$team-overview" \
    -o jsonpath='{.metadata.name}: {.status.conditions[?(@.type=="Available")].status}{"\n"}'
done
```

Both Flux `Kustomization` objects are ready at the same `main@sha1:` revision, and both dashboards print `True`. The first half was Flux; the second half was the Perses Operator.

## Step 4: Prove a commit reaches Perses

Start `kubectl -n gitea port-forward svc/gitea-http 3000:3000` in a second terminal, then change the dashboard's display name and push:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
sed -i.bak 's/name: Payments Overview/name: Payments Overview (from Git)/' dashboards/payments/dashboard-overview.yaml
rm dashboards/payments/dashboard-overview.yaml.bak
git commit -am "Rename the payments dashboard" && git push
cd ..
flux reconcile kustomization payments-dashboards --with-source
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards/payments-overview | jq -r .spec.display.name'
```

Perses answers `Payments Overview (from Git)`. The task forbids changing the files in Git for the final state, so put the name back with `git revert HEAD`, a push and another `flux reconcile`. The grader runs the same round trip itself.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `kubectl apply` the files from your clone | The dashboards appear, but not in any Flux inventory; the grader checks the inventory |
| One Flux `Kustomization` for `./dashboards` | It works, but the task asks for one per team, so each team's delivery fails or succeeds on its own |
| `prune: false` | A dashboard deleted from Git stays in the cluster and in Perses |

## Common mistakes

- Creating the Secret in the wrong namespace. The `GitRepository` and its `secretRef` must be in the same namespace.
- Forgetting the leading `./` or a typo in the path. Flux reports a path that does not exist in the `Kustomization`'s `Ready` message.
