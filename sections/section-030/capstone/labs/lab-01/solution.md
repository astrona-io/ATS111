# Solution: Repair A Dashboard Delivery Pipeline

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the Flux objects, the retired dashboard gone, the latency dashboard fixed and served, and Perses holding exactly what Git holds.

## Step 1: Read the Flux side

```sh
flux get kustomizations
kubectl -n flux-system get kustomization payments-dashboards catalog-dashboards \
  -o jsonpath='{range .items[*]}{.metadata.name}: path={.spec.path} prune={.spec.prune}{"\n"}{end}'
```

`catalog-dashboards` is not ready, and its message says the path `./dashboards/catalg` does not exist: a typo. `payments-dashboards` is ready, but it runs with `prune=false`. Fix both on the objects:

```sh
kubectl -n flux-system patch kustomization catalog-dashboards --type merge -p '{"spec":{"path":"./dashboards/catalog"}}'
kubectl -n flux-system patch kustomization payments-dashboards --type merge -p '{"spec":{"prune":true}}'
```

## Step 2: Remove the orphaned dashboard

`payments-legacy` was deleted from Git while pruning was off. Flux dropped it from its inventory without deleting it, so turning pruning on does not find it again. Check, then delete the object by hand; the operator then deletes it from Perses:

```sh
kubectl -n flux-system get kustomization payments-dashboards \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
kubectl -n payments delete persesdashboard payments-legacy
```

The inventory lists the datasource, `payments-overview` and `payments-latency`, but not `payments-legacy`. Deleting it by hand is the right fix here, because Git already says it should not exist.

## Step 3: Read why Perses refuses the latency dashboard

The latency dashboard is in the cluster, so Flux did its part. Ask the operator:

```sh
kubectl -n payments get persesdashboard payments-latency \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
```

The reason is `ValidationFailed`: the Perses server refused the dashboard because its layout refers to `#/spec/panels/latency`, and the only panel is named `up`.

## Step 4: Fix the dashboard in Git

Start `kubectl -n gitea port-forward svc/gitea-http 3000:3000` in a second terminal, then fix the reference and push:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
sed -i.bak 's|#/spec/panels/latency|#/spec/panels/up|' dashboards/payments/dashboard-latency.yaml
rm dashboards/payments/dashboard-latency.yaml.bak
git commit -am "Point the latency layout at a panel that exists" && git push
cd ..
flux reconcile kustomization payments-dashboards --with-source
flux reconcile kustomization catalog-dashboards
```

Flux applies the changed object, and the operator reconciles it because it changed.

## Step 5: Prove Git, the cluster and Perses agree

```sh
kubectl -n payments get persesdashboard payments-latency \
  -o jsonpath='{.status.conditions[?(@.type=="Available")].status}{"\n"}'
for team in payments catalog; do
  kubectl -n observability exec deploy/tester -- sh -c \
    "curl -s http://perses.perses:8080/api/v1/projects/$team/dashboards | jq -r '.[].metadata.name'"
done
```

`payments-latency` is `Available`. The project `payments` lists `payments-latency` and `payments-overview`, and `catalog` lists `catalog-overview`. If a dashboard still shows an old reason, change an annotation on it to start a reconciliation now.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete `payments-legacy` with `percli` or the API | The object still exists in the cluster, and the operator writes the dashboard back on its next reconciliation |
| Delete `dashboard-latency.yaml` from Git | The refused dashboard disappears, but so does the team's work; the task requires fixing it |
| Patch the `payments-latency` object in the cluster | Flux puts the broken reference back from Git on its next run |

## Common mistakes

- Expecting `prune: true` to remove the legacy dashboard by itself. It is no longer in the inventory.
- Stopping when Flux is ready. A ready `Kustomization` says nothing about whether Perses accepted the dashboard.
