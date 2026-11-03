# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Limit And Harden The Shared Server

## Scenario

The `payments` and `catalog` teams share the Perses server `perses` in the namespace `perses`. The platform team has had two incidents: a pipeline created hundreds of dashboards, and a test pod in another namespace wrote projects directly through the server's API. The namespace `payments` already holds one dashboard.

## Your task

1. Cap the number of `PersesDashboard` objects with a ResourceQuota named `dashboard-cap`: `2` in `payments` and `3` in `catalog`.
2. In the namespace `perses`, create a NetworkPolicy named `perses-ingress` that selects all pods of the namespace and allows ingress on TCP port `8080` only from the namespaces `perses-operator` and `observability`.

## Constraints

- Use `count/persesdashboards.perses.dev` as the quota key.
- Do not delete the existing dashboard.
- The operator must still deliver new dashboards to the server after the policy exists.

## Done when

- Both quotas exist with the right values.
- In `payments` a second dashboard can be created and a third is refused with `exceeded quota`.
- The NetworkPolicy lists exactly the two namespaces and the one port, and the new dashboard becomes `Available`.
