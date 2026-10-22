# Solution: Lock Down Two Tenants Delivered By Flux

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: impersonation on both Flux `Kustomization` objects, no ClusterRoleBinding for the team ServiceAccounts, the permission matrix, and the dashboards in Perses with the cross-namespace dashboard gone.

## Step 1: Read both pipelines

```sh
flux get kustomizations -A
for team in payments catalog; do
  kubectl -n "$team" get kustomization dashboards \
    -o jsonpath='{.metadata.namespace}: serviceAccountName={.spec.serviceAccountName}{"\n"}'
done
```

`dashboards` in `payments` uses `payments-ci` and is not ready; its message is a `Forbidden` error for `system:serviceaccount:payments:payments-ci`. That ServiceAccount has no RoleBinding. `dashboards` in `catalog` is ready but sets no `serviceAccountName`, so kustomize-controller applies its folder with its own broad rights.

## Step 2: Find the extra rights

```sh
kubectl get clusterrolebindings \
  -o jsonpath='{range .items[*]}{.metadata.name}: {range .subjects[*]}{.namespace}/{.name} {end}{"\n"}{end}' \
  | grep -E 'payments-ci|catalog-ci'
```

The ClusterRoleBinding `catalog-ci-admin` gives `catalog-ci` the ClusterRole `cluster-admin`. Remove it, then give both teams the namespace-scoped rights instead.

```sh
kubectl delete clusterrolebinding catalog-ci-admin
```

Save this as `rbac-perses-editors.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: perses-editor
  namespace: payments
rules:
  - apiGroups: ["perses.dev"]
    resources: ["persesdashboards", "persesdatasources"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payments-ci-perses-editor
  namespace: payments
subjects:
  - kind: ServiceAccount
    name: payments-ci
    namespace: payments
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: perses-editor
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: perses-editor
  namespace: catalog
rules:
  - apiGroups: ["perses.dev"]
    resources: ["persesdashboards", "persesdatasources"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: catalog-ci-perses-editor
  namespace: catalog
subjects:
  - kind: ServiceAccount
    name: catalog-ci
    namespace: catalog
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: perses-editor
```

Apply it:

```sh
kubectl apply -f rbac-perses-editors.yaml
```

## Step 3: Remove the cross-namespace dashboard from Git first

The catalog folder holds `payments-takeover.yaml`, a dashboard for the namespace `payments`. Remove it from Git **before** the catalog `Kustomization` impersonates `catalog-ci`: the prune that deletes it from `payments` must still run with kustomize-controller's own rights, because `catalog-ci` will not be allowed to touch `payments`.

Start `kubectl -n gitea port-forward svc/gitea-http 3000:3000` in a second terminal, then:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
git rm dashboards/catalog/payments-takeover.yaml
git commit -m "Keep the catalog folder inside the catalog namespace" && git push
cd ..
flux reconcile kustomization dashboards -n catalog --with-source
kubectl -n payments get persesdashboard payments-takeover
```

The last command answers `NotFound`: Flux pruned the object, and the operator deleted the dashboard from Perses. If it still exists, delete it with `kubectl -n payments delete persesdashboard payments-takeover`.

## Step 4: Make the catalog pipeline act as the team

```sh
kubectl -n catalog patch kustomization dashboards --type merge -p '{"spec":{"serviceAccountName":"catalog-ci"}}'
flux reconcile kustomization dashboards -n catalog --with-source
flux reconcile kustomization dashboards -n payments --with-source
flux get kustomizations -A
```

Both `dashboards` objects are ready. The payments one works now because `payments-ci` has its RoleBinding.

## Step 5: Prove the isolation and the dashboards

```sh
for team in payments catalog; do
  other=catalog; [ "$team" = catalog ] && other=payments
  echo "$team -> $other: $(kubectl auth can-i create persesdashboards.perses.dev -n "$other" --as "system:serviceaccount:$team:$team-ci")"
  kubectl -n observability exec deploy/tester -- sh -c \
    "curl -s http://perses.perses:8080/api/v1/projects/$team/dashboards/$team-overview | jq -r .spec.display.name"
done
```

Both cross-namespace checks print `no`, and Perses answers `Payments Overview` and `Catalog Overview`.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Give `payments-ci` a ClusterRoleBinding too, so its pipeline works | Both teams can write everywhere; the grader rejects any ClusterRoleBinding for them |
| Set `serviceAccountName` on catalog first, then remove the file | The prune of `payments-takeover` runs as `catalog-ci` and is refused, so the `Kustomization` turns not ready |
| Delete `payments-takeover` from the cluster but not from Git | Flux applies it again on the next run, as long as the catalog pipeline still has the rights |

## Common mistakes

- Moving the team `Kustomization` objects to `flux-system`. Flux looks for `serviceAccountName` in the `Kustomization`'s own namespace.
- Forgetting that `cluster-admin` also let `catalog-ci` write RoleBindings; check the whole matrix, not only dashboards.
