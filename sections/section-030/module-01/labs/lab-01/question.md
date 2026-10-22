# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** GitOps For Dashboards With Flux

## Scenario

The `payments` and `catalog` teams keep their Perses datasources and dashboards in the repository `gitops/fleet` on the in-cluster Gitea server, in `dashboards/payments/` and `dashboards/catalog/`. Today someone applies those files by hand. The platform team wants Flux to deliver them instead, so a commit is the only way a dashboard changes.

## Your task

In the namespace `flux-system`:

1. Create a Secret `fleet-auth` with the Gitea credentials (user `gitops`, password `gitops-password`).
2. Create a `GitRepository` named `fleet` for `http://gitea.localtest.me:3000/gitops/fleet.git`, branch `main`, using `fleet-auth`.
3. Create two Flux `Kustomization` objects, `payments-dashboards` for `./dashboards/payments` and `catalog-dashboards` for `./dashboards/catalog`, both with pruning on.

## Constraints

- Do not apply the dashboard or datasource files with `kubectl`; Flux must apply them.
- Do not change the files in Git.
- Keep pruning on for both Flux `Kustomization` objects.

## Done when

- The `GitRepository` `fleet` and both Flux `Kustomization` objects are `Ready`, on the right paths, with `prune: true`.
- Each team's `PersesDashboard` `<team>-overview` is in the inventory of the team's `Kustomization`, is `Available`, and Perses serves it with the name from Git.
- A change pushed to `dashboards/payments/dashboard-overview.yaml` reaches the Perses API. The grader pushes such a change itself, checks it, and puts the file back.
