# Overview: Isolate Teams That Share One Perses Server (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the Perses Operator, a Perses server, Gitea and Flux, and two team namespaces, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it as a cluster administrator, so `--as` works.
- Helm 3.22.1, `percli` v0.54.0 and the Flux CLI 2.9.6 on your PATH.
- The **Perses Operator v0.5.0** and a `Perses` resource `perses` in the namespace `perses`, running **Perses v0.54.0** at `http://perses.perses:8080`.
- The namespaces `payments` and `catalog`, each with a ServiceAccount (`payments-ci`, `catalog-ci`) that has no permissions yet.
- **Gitea** in the namespace `gitea` with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`), holding `dashboards/payments/` and `dashboards/catalog/`.
- The **Flux v2.9.6** controllers in `flux-system`, with no `GitRepository` and no `Kustomization` yet.
- Prometheus and a `tester` pod with `curl` and `jq` in the namespace `observability`.

## Helpers

Paste these once in each new terminal. `team_can` asks whether a team's ServiceAccount may do something. `as_team` runs a `kubectl` command as a team's ServiceAccount. `perses_dashboards` lists the dashboards Perses holds for a project.

```sh
team_can() {
  local team="$1"; shift
  kubectl auth can-i "$@" --as "system:serviceaccount:$team:$team-ci"
}
as_team() {
  local team="$1"; shift
  kubectl "$@" --as "system:serviceaccount:$team:$team-ci"
}
perses_dashboards() {
  kubectl -n observability exec deploy/tester -- sh -c \
    "curl -s http://perses.perses:8080/api/v1/projects/$1/dashboards | jq -r '.[].metadata.name'"
}
```

Use them like this: `team_can payments create persesdashboards.perses.dev -n catalog`, `as_team payments -n payments get persesdashboards`, `perses_dashboards payments`.

## Practice tasks

- Give `payments-ci` the ClusterRole `edit` with a RoleBinding in `payments`, and check `team_can payments create persesdashboards.perses.dev -n payments`. Read which verbs the built-in `edit` role grants on custom resources, and why.
- Bind `catalog-ci` to `cluster-admin` with a ClusterRoleBinding, then list everything `team_can catalog` now allows in `payments`. Delete the binding afterwards.
- Set `serviceAccountName: catalog-ci` on a Flux `Kustomization` in `catalog` before the RoleBinding exists, and read its `Ready` message.
- Add a file to `dashboards/catalog/` that targets the namespace `payments`, push it, and watch the impersonating `Kustomization` refuse it.
