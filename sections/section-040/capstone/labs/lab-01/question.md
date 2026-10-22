# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Multi-Tenant Isolation

## Scenario

Flux delivers both teams' dashboards from `gitops/fleet`. Each team has a Flux `Kustomization` named `dashboards` in its own namespace, reading the `GitRepository` `fleet` in `flux-system` and the team's folder under `dashboards/`. The setup grew in a hurry:

- The `payments` pipeline has not applied anything for days.
- The `catalog` pipeline works, but someone noticed that a dashboard from the catalog folder sits in the `payments` namespace.
- An old note says `catalog-ci` "needed more rights" at some point.

## Your task

Lock both tenants down so that each team's Git folder can only change its own namespace, and both teams' dashboards reach Perses.

## Constraints

- Both Flux `Kustomization` objects must act as their team's ServiceAccount (`payments-ci`, `catalog-ci`).
- Team ServiceAccounts get rights through Roles and RoleBindings in their own namespace only. No ClusterRoleBinding may name them.
- Keep both teams' overview dashboards and datasources in Git; remove only what does not belong.

## Done when

- The Flux `Kustomization` `dashboards` in `payments` and in `catalog` use `serviceAccountName` `payments-ci` and `catalog-ci` and are `Ready`.
- No ClusterRoleBinding names `payments-ci` or `catalog-ci`.
- Each team ServiceAccount may create Perses dashboards and datasources in its own namespace, and may not create dashboards in the other team's namespace, RoleBindings, `PersesGlobalDatasource` objects or `Perses` objects.
- No `PersesDashboard` named `payments-takeover` exists, neither in the cluster nor in Perses, and the catalog folder in Git holds no file for the `payments` namespace.
- Both teams' datasources and dashboards are `Available`, and Perses serves `Payments Overview` and `Catalog Overview`.
