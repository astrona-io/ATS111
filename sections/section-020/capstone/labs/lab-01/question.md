# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Dashboards And Datasources As Kubernetes Resources

## Scenario

The platform team rebuilt the shared Perses server as the `Perses` resource `perses` in the namespace `perses`. Since then, the `payments` dashboard and datasource never reach Perses. The `catalog` team has a different complaint: their datasource shows up but returns no data, and their dashboard is missing.

Every team object selects the server with `instanceSelector` on `app.kubernetes.io/instance: perses`, and the teams want to keep it that way.

## Your task

1. Read the conditions of every `PersesDatasource` and `PersesDashboard` in `payments` and `catalog`, and find each cause.
2. Fix the causes so that both teams' datasources and dashboards are in Perses and both datasources return data.

## Constraints

- **Keep the selectors.** Every object must keep `instanceSelector.matchLabels` with `app.kubernetes.io/instance: perses`.
- Fix the `Perses` resource in place; do not delete it and create it again.
- Do not create anything through `percli` or the Perses API.

## Done when

- The `Perses` resource itself carries the label `app.kubernetes.io/instance: perses` in its `metadata.labels`, and it is the original object.
- The `PersesDatasource` `prometheus` and the `PersesDashboard` `<team>-overview` in `payments` and `catalog` are `Available`, and Perses serves both dashboards with the names `Payments Overview` and `Catalog Overview`.
- A query through each team's datasource returns `success`.
- Every object still selects the server with `app.kubernetes.io/instance: perses`.
