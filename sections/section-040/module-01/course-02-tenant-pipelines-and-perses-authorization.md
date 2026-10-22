# Tenant Pipelines And Perses Authorization

Rights for a team's ServiceAccount do nothing if the team's dashboards reach the cluster through a pipeline that runs with more rights. Flux's kustomize-controller is such a pipeline: by default it applies everything with its own identity, which may write anywhere. This part makes a team's Flux `Kustomization` act as the team, so its Git folder can only change its own namespace, and then places Perses' own login and roles next to Kubernetes RBAC.

## A Flux Kustomization that acts as the team

A Flux `Kustomization` has the field `spec.serviceAccountName`. When it is set, kustomize-controller impersonates that ServiceAccount for every apply and every prune of that `Kustomization`. Flux looks the ServiceAccount up in the namespace of the `Kustomization` itself, so a team's `Kustomization` lives in the team's namespace. It can still read the shared `GitRepository` in `flux-system`, because a cross-namespace source reference is allowed by default.

The commands below need the Role `perses-editor` and the RoleBinding for `catalog-ci` in the namespace `catalog`, with the same rules as for `payments`: every normal verb on `persesdashboards` and `persesdatasources` in the API group `perses.dev`. Create them quickly with `kubectl`:

<!-- astrona:playground:renew -->

```sh
kubectl -n catalog create role perses-editor --verb=get,list,watch,create,update,patch,delete \
  --resource=persesdashboards.perses.dev,persesdatasources.perses.dev
kubectl -n catalog create rolebinding catalog-ci-perses-editor --role=perses-editor \
  --serviceaccount=catalog:catalog-ci
```

Flux also needs to read the repository. Create the credentials Secret, then the source and the team's `Kustomization`:

```sh
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username=gitops --password=gitops-password
```

Save this as `flux-catalog-tenant.yaml`:

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
  name: dashboards
  namespace: catalog
spec:
  interval: 5m
  serviceAccountName: catalog-ci
  sourceRef:
    kind: GitRepository
    name: fleet
    namespace: flux-system
  path: ./dashboards/catalog
  prune: true
```

Apply it:

```sh
kubectl apply -f flux-catalog-tenant.yaml
```

Then check the result:

```sh
flux reconcile kustomization dashboards -n catalog --with-source
flux get kustomizations -n catalog
kubectl -n catalog get persesdatasource,persesdashboard
```

The `Kustomization` is ready, and the two objects from `dashboards/catalog/` exist in `catalog`: kustomize-controller applied them as `system:serviceaccount:catalog:catalog-ci`. If a file in that folder named another namespace, the apply would fail with `Forbidden`, the `Kustomization` would turn not ready, and nothing in the other namespace would change. The team's Git folder can now do exactly what the team's ServiceAccount can do.

## Lock the defaults down

Impersonation only protects the `Kustomization` objects that set it. Flux has controller flags that make the safe choice the default for the whole cluster; the Flux documentation calls this the multi-tenancy lockdown:

| Flag | On which controllers | What it prevents |
| --- | --- | --- |
| `--default-service-account=<name>` | kustomize-controller, helm-controller | A `Kustomization` without `serviceAccountName` running with the controller's own rights; it impersonates this account instead |
| `--no-cross-namespace-refs=true` | all controllers | An object in one namespace referring to a source or Secret in another namespace |
| `--no-remote-bases=true` | kustomize-controller | Kustomize files pulling remote bases from outside the source |

With `--no-cross-namespace-refs=true`, the team `Kustomization` above could no longer use the `GitRepository` in `flux-system`; each team then gets its own `GitRepository` in its own namespace. The flags are set by patching the Flux controllers, usually in the `flux-system` folder that `flux bootstrap` writes.

## Perses' own authentication and roles

Everything so far is Kubernetes RBAC, and it controls who may change the custom resources. Perses has its own, separate layer for people who use the Perses server directly. With `security.enable_auth: true` in the server configuration, users must log in, through native Perses users or an external OpenID Connect or OAuth provider. Perses then has its own roles: a `Role` and a `RoleBinding` per Perses project, and a `GlobalRole` and a `GlobalRoleBinding` for the whole server. These are Perses resources inside the server, not Kubernetes objects.

The two layers meet at the operator. The operator writes dashboards through the Perses API, so when authentication is on, it must log in too. The `Perses` resource has a `spec.client` field for that, with `basicAuth` (a user name and a password from a Secret), `oauth`, `tls` client certificates, or `kubernetesAuth`, which makes the operator authenticate with Kubernetes credentials to a server set up to accept them. A common split is: Kubernetes RBAC decides who may deliver dashboards as code, and Perses roles decide who may read or edit them in the user interface.

You can now make a team's Git delivery act as the team, name the Flux lockdown options, and say which layer controls which kind of change. The multi-tenancy picture is complete: namespaces as projects, RBAC per namespace, impersonating pipelines, and Perses roles for people.

## Common pitfalls

> [!WARNING]
> - **Putting the team `Kustomization` in `flux-system`.** Flux looks for `serviceAccountName` in the `Kustomization`'s own namespace, so the ServiceAccount is not found there.
> - **Setting `serviceAccountName` before the RoleBinding exists.** Every apply fails with `Forbidden` until the team's rights are in place.
> - **Turning on `--no-cross-namespace-refs` with shared sources.** Every team `Kustomization` that points at `flux-system` stops; give each team its own `GitRepository` first.
> - **Enabling Perses authentication without configuring `spec.client`.** The operator can no longer write to the server, and every dashboard fails with a connection or permission error.
