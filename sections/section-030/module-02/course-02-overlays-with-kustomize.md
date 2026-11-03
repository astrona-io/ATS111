# Overlays With Kustomize

Two teams often want the same dashboard with small differences: the namespace, a name prefix and a display name. Copying the file for each team gives two files to keep in step. A Kustomize base with one overlay per team keeps a single source. This part builds that structure, previews it without the cluster, and delivers it with Flux.

## The kustomization file

Kustomize reads a file called `kustomization.yaml` in a folder. It lists `resources`, which are files or other folders, and transformations to apply: a `namespace` for every object, a `namePrefix`, labels, and `patches`. The result is plain manifests. Flux runs Kustomize itself when the folder it applies contains a `kustomization.yaml`, and applies every manifest in the folder when it does not.

This is the file `kustomization.yaml` of Kustomize, not the Flux `Kustomization` object. They share a name and nothing else.

## The repository layout

The repository `gitops/fleet` holds a base and two overlays:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
find base overlays -type f | sort
```

The port-forward from the previous module must be running: `kubectl -n gitea port-forward svc/gitea-http 3000:3000` in a second terminal. The listing shows `base/service-health/` with a `kustomization.yaml` and `dashboard.yaml`, and one `kustomization.yaml` in each of `overlays/payments/` and `overlays/catalog/`. The base dashboard has the name `service-health` and no namespace. Read the overlay for payments:

```sh
cat overlays/payments/kustomization.yaml
```

It sets `namespace: payments`, `namePrefix: payments-`, lists the base as a resource, and patches the display name.

## Preview the result

Kustomize is built into `kubectl`. Build an overlay without applying anything:

```sh
kubectl kustomize overlays/payments
kubectl kustomize overlays/catalog | grep -E 'name:|namespace:'
```

The first command prints a `PersesDashboard` named `payments-service-health` in the namespace `payments` with the patched display name. The second shows the catalog names. Building before every commit is the cheapest check there is, because it needs no cluster access and shows exactly what Flux would apply.

## Deliver both overlays

One Flux `Kustomization` per overlay. Save this as `flux-overlays.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: payments-service-health
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./overlays/payments
  prune: true
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: catalog-service-health
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./overlays/catalog
  prune: true
```

Apply it:

```sh
kubectl apply -f flux-overlays.yaml
```

Then check the result:

```sh
flux get kustomizations
kubectl -n payments get persesdashboards
kubectl -n catalog get persesdashboards
```

Both deliveries become `Ready`, and the namespaces hold `payments-service-health` and `catalog-service-health`. Both are served by Perses in the project of their namespace.

## Change the base once

Edit `base/service-health/dashboard.yaml`, change the `duration` from `1h` to `6h`, commit and push, then ask Flux to fetch the change:

```sh
git commit -am "Show six hours by default" && git push
flux reconcile source git fleet
flux reconcile kustomization payments-service-health
flux reconcile kustomization catalog-service-health
```

Both dashboards change. One edit reached two teams. That is the benefit and the cost: a base change needs the care of a change to shared code, and a preview with `kubectl kustomize` for each overlay before the push.

## What an overlay should not do

An overlay changes values. It should not rebuild the structure of a dashboard, because a patch that replaces the list of panels hides the base and gives you two files to keep in step again. When two teams need different panels, give them different bases.

You can now write a base and overlays, preview the output, and deliver it. The open question is a value that differs per cluster and should not be written into the files at all.

## Common pitfalls

> [!WARNING]
> - **Adding a `kustomization.yaml` to a folder that did not have one.** Flux then applies only what the file lists, and files it does not list are silently skipped, and pruned.
> - **Forgetting `namespace:` in the overlay.** The objects land in the namespace of the Flux `Kustomization` or fail.
> - **Pushing a base change without building each overlay.** A patch that no longer matches fails the build for every team.
> - **Using `namePrefix` and not updating references.** A reference by name is not renamed by the prefix.
