# Dashboards In Git, Applied By Flux

The team's dashboard objects already exist as files; this part puts them where a GitOps agent can find them and connects that agent. You will look at the repository, give Flux the credentials to read it, point one Flux `Kustomization` at one team's folder, and push a change that travels from a commit into Perses without a single `kubectl apply` of the dashboard.

## The repository layout

The repository `gitops/fleet` on the in-cluster Gitea server holds one folder per team under `dashboards/`. Each folder holds that team's `PersesDatasource` and `PersesDashboard` files, exactly as you would apply them with `kubectl`. There are no `Namespace` objects in the folders: the platform creates the team namespaces, so the team's folder only holds what the team owns.

Your machine reaches Gitea through a port-forward. Start it in a second terminal and leave it running:

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Then clone the repository. The name `gitea.localtest.me` resolves to `127.0.0.1`, so the request goes through the port-forward; if it does not resolve, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`. The user `gitops` with the password `gitops-password` is a lab-only account on a plain HTTP server; a real Git server uses HTTPS or SSH.

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
find fleet/dashboards -type f
```

The listing shows `datasource.yaml` and `dashboard-overview.yaml` in `dashboards/payments/` and in `dashboards/catalog/`. The same name works inside the cluster too, because the playground added a DNS rewrite that sends `gitea.localtest.me` to the Gitea Service, so Flux uses the same URL as you.

## Connect Flux to the repository

Flux reads Git with source-controller and applies files with kustomize-controller. Two objects drive them: a `GitRepository`, which says which repository and branch to fetch and how often, and a Flux `Kustomization`, which says which folder of that repository to apply. The Flux `Kustomization` object is not the Kustomize file `kustomization.yaml`; the folders here need no such file, because Flux applies every manifest in a folder that has none.

The repository is private, so source-controller needs credentials. The Flux CLI creates a Secret in the format Flux expects:

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
```

Now the source and one team's sync. Save this as `flux-payments-dashboards.yaml`:

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
```

Apply it:

```sh
kubectl apply -f flux-payments-dashboards.yaml
```

Then check the result:

```sh
flux get sources git
flux get kustomizations
kubectl -n payments get persesdatasource,persesdashboard
```

The `GitRepository` `fleet` is ready at a revision such as `main@sha1:...`, and the `Kustomization` `payments-dashboards` is ready at the same revision. The two objects from `dashboards/payments/` now exist in the namespace `payments`. One step later, the Perses Operator reconciled them and copied them into the project `payments`, with no Flux involvement at all.

## A commit, all the way to Perses

Change the dashboard's display name in Git and push. That one commit is now the whole delivery:

```sh
cd fleet
sed -i.bak 's/name: Payments Overview/name: Payments Overview (from Git)/' dashboards/payments/dashboard-overview.yaml
rm dashboards/payments/dashboard-overview.yaml.bak
git commit -am "Rename the payments dashboard" && git push
cd ..
```

Flux fetches the repository every minute and applies the folder every five, so the change arrives on its own. Ask for it now instead of waiting:

```sh
flux reconcile kustomization payments-dashboards --with-source
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards/payments-overview | jq -r .spec.display.name'
```

Perses answers `Payments Overview (from Git)`. Three components did the work, in order. Source-controller fetched the new commit. Kustomize-controller applied the changed `PersesDashboard` with server-side apply. The Perses Operator saw the changed object and updated the dashboard in Perses through its API.

```mermaid
flowchart LR
    G["Git: gitops/fleet"] -->|"fetch"| S["source-controller"]
    S -->|"artifact"| K["kustomize-controller"]
    K -->|"apply"| A["PersesDashboard"]
    A -->|"watch"| O["perses-operator"]
    O -->|"REST API"| P["Perses"]
```

The diagram shows the commit's path: Flux carries it from Git into the cluster, and the operator carries it from the cluster into Perses.

You can now deliver one team's dashboards from Git and follow a commit into Perses. The open question is what happens when the cluster or Perses changes without a commit.

## Common pitfalls

> [!WARNING]
> - **Putting `Namespace` objects in a team folder.** Keep namespaces with the platform; a team's sync should only touch the team's namespace.
> - **Confusing the Flux `Kustomization` with `kustomization.yaml`.** The first is a Flux object in the cluster; the second is an optional Kustomize file in the folder.
> - **Waiting five minutes after a push.** Run `flux reconcile kustomization <name> --with-source` to fetch and apply now.
> - **Blaming Flux when Perses is wrong.** Once the custom resource is correct in the cluster, Flux is done; read the object's conditions for the operator's side.
