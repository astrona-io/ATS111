# Overview: Operate Flux Delivery For Perses (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the operator, a Perses server, Gitea and Flux, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Helm 3.22.1, `percli` v0.54.0 and the Flux CLI on your PATH.
- The **Perses Operator v0.5.0** in `perses-operator`, and a Perses server at `http://perses.perses:8080`.
- Gitea in the namespace `gitea` with the repository `gitops/fleet`, user `gitops`, password `gitops-password`.
- The **Flux v2.9.6** controllers in `flux-system`. Nothing is delivered yet.
- The empty namespaces `payments` and `catalog`.
- Prometheus and a `tester` pod in `observability`.

## What the repository holds

- `dashboards/payments/` and `dashboards/catalog/`: a datasource and a dashboard per team.
- `base/service-health/` and `overlays/payments/`, `overlays/catalog/`: a Kustomize base with an overlay per team.
- `ops/datasources/` and `ops/dashboards/`: a datasource with the address `${PROMETHEUS_URL}` and a dashboard. The module lab delivers these.

## Reach Gitea

Run this in a second terminal and leave it running:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

Clone with `git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git`.

## Practice tasks

- Make `catalog-dashboards` depend on `payments-dashboards`, break the path of the first, and read what the second reports.
- Add a `healthChecks` entry for a Deployment and set a `timeout` that is too short. Read the result.
- Build both overlays with `kubectl kustomize` and compare them.
- Add a third overlay for a new team namespace and deliver it.
- Deliver `ops/datasources` with and without `postBuild.substituteFrom` and compare the conditions of the datasource.
- Use `flux diff kustomization` on a local change before you push it.
- Suspend a delivery, edit an object by hand, and resume. Watch Flux restore it.
- Run `flux trace` on an object and on an object that was applied by hand.
