# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** GitOps For Dashboards With Flux

## Scenario

Flux delivers the `payments` and `catalog` dashboards from `gitops/fleet` with the Flux `Kustomization` objects `payments-dashboards` and `catalog-dashboards` in `flux-system`. Three complaints reached the platform team this week:

- The `catalog` team's dashboards have never appeared.
- The `payments` team retired the dashboard `payments-legacy` and deleted it from Git, but it is still in Perses.
- The `payments` team added a `payments-latency` dashboard to Git; it exists in the cluster but never appears in Perses.

## Your task

Find and fix the cause of each complaint. Change the pipeline through Git and the Flux objects, not through the Perses API.

## Constraints

- Keep `dashboards/payments/dashboard-latency.yaml` in Git; fix it, do not delete it.
- Both Flux `Kustomization` objects must keep running from `gitops/fleet`; do not apply dashboard files with `kubectl`.
- Do not create or delete dashboards through `percli` or the Perses API.

## Done when

- `payments-dashboards` and `catalog-dashboards` are `Ready`, apply `./dashboards/payments` and `./dashboards/catalog`, and both prune.
- `payments-legacy` is gone from the namespace `payments` and from Perses.
- `dashboard-latency.yaml` in Git no longer refers to a missing panel, its `PersesDashboard` is `Available`, and Perses serves it.
- The Perses project `payments` holds exactly `payments-latency` and `payments-overview`, and `catalog` holds exactly `catalog-overview`.
