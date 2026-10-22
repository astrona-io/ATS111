# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Multi-Tenant Isolation

## Scenario

The `payments` and `catalog` teams share one Perses server. Each team's pipeline runs as a ServiceAccount in the team's namespace: `payments-ci` in `payments` and `catalog-ci` in `catalog`. Today those ServiceAccounts have no rights, so the platform team applies every dashboard by hand. The teams should deliver their own Perses objects, and neither may touch the other's.

## Your task

1. In each team namespace, give the team's ServiceAccount the right to read, create, change and delete `PersesDashboard` and `PersesDatasource` objects in that namespace only.
2. As `payments-ci`, apply a `PersesDatasource` `prometheus` (default, HTTP proxy to `http://prometheus.observability.svc.cluster.local:9090`) and a `PersesDashboard` `payments-overview` named `Payments Overview` in `payments`.
3. As `catalog-ci`, apply the same pair in `catalog`, with the dashboard `catalog-overview` named `Catalog Overview`.

All four objects select the server with `instanceSelector` on `app.kubernetes.io/instance: perses`.

## Constraints

- Use Roles and RoleBindings in the team namespaces. Do not bind a team ServiceAccount with a ClusterRoleBinding.
- A team ServiceAccount must not be able to create RoleBindings, `PersesGlobalDatasource` objects or `Perses` objects.

## Done when

- `kubectl auth can-i` says each team ServiceAccount may create `persesdashboards.perses.dev` and `persesdatasources.perses.dev` in its own namespace, and may not create dashboards in the other team's namespace, RoleBindings, `PersesGlobalDatasource` objects or `Perses` objects.
- No ClusterRoleBinding names `payments-ci` or `catalog-ci`.
- Both teams' datasources and dashboards are `Available`, and Perses serves both dashboards with their names.
