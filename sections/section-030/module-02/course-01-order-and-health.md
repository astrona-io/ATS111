# Order And Health

Flux applies each `Kustomization` on its own schedule, with no order between them. Most dashboards do not care, and some deliveries do: an object that needs a namespace, a datasource or a CRD that another delivery creates fails until that delivery is done. This part sets an order with `dependsOn`, makes a delivery wait for health with `healthChecks`, and shows what a blocked delivery reports.

## What dependsOn does

The field `spec.dependsOn` of a Flux `Kustomization` lists other `Kustomization` objects by name and namespace. Flux does not reconcile the object until every listed object is `Ready`. A dependency that is not ready does not make the object fail permanently: Flux reports that it is waiting and tries again at the next interval. When the dependency becomes ready, the waiting object applies.

`Ready` here means the dependency finished its last apply without error and passed its own health checks. That is why the two features belong together: `dependsOn` is only as strict as the checks of the object it waits for.

## Health checks

By default a Flux `Kustomization` is `Ready` when the apply succeeded, not when the objects work. Two fields change that. `spec.wait: true` makes Flux wait until every object it applied is healthy, judged by the standard status of the object. `spec.healthChecks` lists specific objects to wait for, including objects that another delivery created. Both are bounded by `spec.timeout`, and a delivery whose checks do not pass in time is not `Ready`.

A list entry names an object with `apiVersion`, `kind`, `name` and `namespace`. Deployments, StatefulSets and other built-in workloads are judged by their rollout status.

## Set up the source

The commands need the Gitea credentials and the source. Flux reads Git with source-controller:

<!-- astrona:playground:renew -->

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
```

Save this as `flux-source.yaml`:

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
```

Apply it:

```sh
kubectl apply -f flux-source.yaml
```

Then check the result:

```sh
flux get sources git
```

The source `fleet` is `True` with a message that names the branch and a revision.

## Order two deliveries

Save this as `flux-ordered.yaml`. The delivery for `catalog` waits for the delivery for `payments`, and the delivery for `payments` waits for the Perses server to roll out:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: payments-dashboards
  namespace: flux-system
spec:
  interval: 5m
  timeout: 3m
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./dashboards/payments
  prune: true
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: perses
      namespace: perses
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: catalog-dashboards
  namespace: flux-system
spec:
  interval: 5m
  dependsOn:
    - name: payments-dashboards
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./dashboards/catalog
  prune: true
```

Apply it:

```sh
kubectl apply -f flux-ordered.yaml
```

Then check the result:

```sh
flux get kustomizations
kubectl -n catalog get persesdashboards
```

Both deliveries become `Ready`, and the dashboard `catalog-overview` exists. A `dependsOn` entry without a namespace refers to the namespace of the object itself.

## See a blocked delivery

Break the first delivery on purpose by pointing it at a folder that does not exist, then ask for a fresh run of the second:

```sh
kubectl -n flux-system patch kustomization payments-dashboards --type merge \
  -p '{"spec":{"path":"./dashboards/paymnts"}}'
flux reconcile kustomization payments-dashboards --with-source
flux reconcile kustomization catalog-dashboards
flux get kustomizations
```

The first delivery is not ready, and its message names the path. The second one waits and reports that its dependency is not ready. The objects it already applied stay in place, because a blocked delivery does not delete anything. Restore the path and the second delivery recovers:

```sh
kubectl -n flux-system patch kustomization payments-dashboards --type merge \
  -p '{"spec":{"path":"./dashboards/payments"}}'
flux reconcile kustomization payments-dashboards --with-source
flux get kustomizations
```

You can now order deliveries, make readiness mean health, and recognise a blocked delivery. A graph of dependencies is a risk if it has a loop, so keep it as a short chain, not a web.

## Common pitfalls

> [!WARNING]
> - **Assuming Flux applies objects in the order of the listing.** There is no order without `dependsOn`.
> - **Adding `dependsOn` and leaving the dependency without checks.** It is ready as soon as the apply finished, not when the objects work.
> - **A `timeout` shorter than a rollout.** The delivery fails although nothing is wrong.
> - **Building a loop of dependencies.** Both objects wait forever.
