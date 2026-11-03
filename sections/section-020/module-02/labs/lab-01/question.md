# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Route And Shape Team Resources

## Scenario

The payments team wants to try its new dashboard before production users see it. A second Perses server named `staging` already runs in the namespace `perses-staging`, and the production server is `perses` in the namespace `perses`. Neither server has a team resource yet. The namespace `payments` exists and is empty.

The team also wants the staging server to read Prometheus through a datasource that allows only the queries a dashboard needs.

## Your task

In the namespace `payments`:

1. Declare a `PersesDashboard` named `checkout` that only the staging server receives. It needs a display name and a duration, and may have no panels.
2. Declare a `PersesDatasource` named `prometheus` that only the staging server receives. It uses an `HTTPProxy` to `http://prometheus.observability.svc.cluster.local:9090` and allows `GET` on exactly these paths: `/api/v1/query`, `/api/v1/query_range`, `/api/v1/labels`, `/api/v1/label/([a-zA-Z0-9_-]+)/values` and `/api/v1/series`.
3. Label the production server `perses` with `env=production`, so that selectors can tell the servers apart.

## Constraints

- Select servers with `instanceSelector`. Do not copy objects into other namespaces.
- Do not change the `staging` resource except through the existing label `env=staging`.
- Do not allow any path outside the list in the datasource.

## Done when

- Both objects are `Available=True`.
- The staging server has the dashboard `checkout` and the datasource `prometheus` in the project `payments`.
- The production server does not have the dashboard `checkout`.
- A query for `up` through the datasource on the staging server returns `success`.
- The datasource on the staging server lists the five paths and no other path.
