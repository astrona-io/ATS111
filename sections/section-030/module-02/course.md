# Operate Flux Delivery For Perses

Delivering a folder of dashboards with one Flux `Kustomization` works until a team needs more: a datasource that must exist before a dashboard, the same dashboard for two teams with different names, an address that differs per environment, or a sync that stops and says nothing useful. This module covers the Flux features that solve those four cases and the commands that show why a delivery is stuck.

Keep the sentence from the previous module: **Flux makes the cluster match Git, and the operator makes Perses match the cluster.** Every problem in this module is on the first half of that sentence, so you can find it without looking at Perses.

The module has four parts. **Order And Health** uses `dependsOn` and `healthChecks` to start one delivery after another. **Overlays With Kustomize** builds two team dashboards from one base. **Variables From The Cluster** fills values into files with `postBuild` substitution. **Find Out Why A Sync Is Stuck** reads the status, events and logs of a delivery. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Order Flux `Kustomization` objects with `dependsOn`, and say what a dependency that is not ready does.
- Add `healthChecks` and `timeout` so a delivery is only ready when the objects it names are healthy.
- Build several team dashboards from one base with a Kustomize overlay, and preview the result with `kubectl kustomize`.
- Fill values from a ConfigMap into manifests with `postBuild.substituteFrom`, and say which syntax Flux substitutes.
- Use `flux get`, `flux events`, `flux logs`, `flux trace`, `flux diff` and `flux suspend` to find why a delivery is stuck.

## Before you start

You need the previous module: a `GitRepository`, a Flux `Kustomization` per folder, and the split of work between Flux and the operator. You also need Kustomize basics: a `kustomization.yaml` that lists resources.

Your playground is a single-node `kind` cluster with the **Perses Operator v0.5.0**, a Perses server (**Perses v0.54.0**) at `http://perses.perses:8080`, Gitea with the repository `gitops/fleet`, and the **Flux v2.9.6** controllers. The repository holds the team folders from the previous module, a base dashboard with two overlays, and a folder `ops/` that the lab uses. The namespaces `payments` and `catalog` exist and are empty.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
