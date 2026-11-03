# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Operate Flux Delivery For Perses

## Scenario

The platform team keeps the payments operations folders in the repository `gitops/fleet` on the in-cluster Gitea server: `ops/datasources` holds a `PersesDatasource` whose address is the variable `${PROMETHEUS_URL}`, and `ops/dashboards` holds the dashboard `payments-ops`. The Flux source `fleet` and the credentials already exist in `flux-system`. The ConfigMap `platform-vars` in `flux-system` has the key `PROMETHEUS_URL`. Nothing delivers the folders yet.

## Your task

In the namespace `flux-system`, create two Flux `Kustomization` objects:

1. `ops-datasources` for `./ops/datasources`. It fills the variables from the ConfigMap `platform-vars`, prunes, and has a health check on the Deployment `perses` in the namespace `perses`.
2. `ops-dashboards` for `./ops/dashboards`. It prunes and does not apply until `ops-datasources` is ready.

## Constraints

- Do not apply the files in `ops/` with `kubectl`; Flux must apply them.
- Do not change the files in Git.
- Do not write the address into the Flux `Kustomization` or into Git; it comes from the ConfigMap.

## Done when

- The source `fleet` and both Flux `Kustomization` objects are `Ready`.
- `ops-dashboards` depends on `ops-datasources`.
- `ops-datasources` uses `platform-vars` as a substitution source and has the health check.
- The `PersesDatasource` `ops-prometheus` in `payments` is `Available` with the address from the ConfigMap, and the `PersesDashboard` `payments-ops` is `Available` and served by Perses.
