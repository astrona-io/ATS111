# Overview: Reconcile Dashboards From Git (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the Perses Operator, a Perses server, a Git server and the Flux controllers, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Helm 3.22.1, `percli` v0.54.0 and the Flux CLI 2.9.6 on your PATH.
- The **Perses Operator v0.5.0** and a `Perses` resource `perses` in the namespace `perses`, running **Perses v0.54.0** at `http://perses.perses:8080`.
- **Gitea** in the namespace `gitea` with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`, plain HTTP). It holds `dashboards/payments/` and `dashboards/catalog/`, each with a `PersesDatasource` and a `PersesDashboard`.
- The **Flux v2.9.6** controllers in `flux-system`, with no `GitRepository` and no `Kustomization` yet.
- Prometheus and a `tester` pod with `curl` and `jq` in the namespace `observability`, and the empty namespaces `payments` and `catalog`.

## Helpers

Paste these once in each new terminal. `dashboard_name` prints the display name Perses holds for a team's overview dashboard. `sync_now` makes Flux fetch and apply a team's folder at once. `show_inventory` prints what a Flux `Kustomization` applied.

```sh
dashboard_name() {
  kubectl -n observability exec deploy/tester -- sh -c \
    "curl -s http://perses.perses:8080/api/v1/projects/$1/dashboards/$1-overview | jq -r .spec.display.name"
}
sync_now() {
  flux reconcile kustomization "$1-dashboards" --with-source
}
show_inventory() {
  kubectl -n flux-system get kustomization "$1-dashboards" \
    -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
}
```

Use them like this: `dashboard_name payments`, `sync_now payments`, `show_inventory payments`.

For `git` on your machine, run `kubectl -n gitea port-forward svc/gitea-http 3000:3000` in a second terminal and clone `http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git`. For the Perses user interface, run `kubectl -n perses port-forward svc/perses 8080:8080` and browse to `http://perses.localtest.me:8080`.

## Practice tasks

- Create the Flux `Kustomization` `catalog-dashboards` with `prune: false`. Delete `dashboards/catalog/dashboard-overview.yaml` from Git, sync, and check the cluster and Perses. Then set `prune: true` and check again.
- Edit the payments dashboard title in the Perses user interface. Run `sync_now payments` and check the title; then change an annotation on the object and check again.
- Suspend the Flux `Kustomization` with `flux suspend kustomization payments-dashboards`, edit the object by hand, and see that nothing puts it back until you run `flux resume kustomization payments-dashboards`.
- Add a third dashboard file to `dashboards/payments/`, push, sync, and find it in `show_inventory payments` and in Perses.
