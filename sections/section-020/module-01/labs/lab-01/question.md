# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Dashboards And Datasources As Kubernetes Resources

## Scenario

Two teams, `payments` and `catalog`, move onto the shared Perses server. The platform team created their namespaces and runs the server as the `Perses` resource `perses` in the namespace `perses`, labelled `app.kubernetes.io/instance: perses`. Each team wants its own Prometheus datasource and an overview dashboard, delivered as Kubernetes objects so they live with the team's other manifests.

## Your task

In each of the namespaces `payments` and `catalog`:

1. Declare a `PersesDatasource` named `prometheus`, set as the project's default, with an HTTP proxy to `http://prometheus.observability.svc.cluster.local:9090`.
2. Declare a `PersesDashboard` named `<team>-overview` (`payments-overview` and `catalog-overview`) with the display name `Payments Overview` or `Catalog Overview`, and at least one panel that queries Prometheus.
3. Make every object select the Perses server with `instanceSelector` on the label `app.kubernetes.io/instance: perses`.

## Constraints

- Deliver everything as custom resources. Do not create the dashboards or datasources with `percli` or the Perses API.
- Do not change the `Perses` resource.

## Done when

- Perses has the projects `payments` and `catalog`.
- In each namespace, the `PersesDatasource` `prometheus` and the `PersesDashboard` `<team>-overview` are `Available`, and the Perses API serves the dashboard with the right display name.
- A query through each team's datasource, at `/proxy/projects/<team>/datasources/prometheus/api/v1/query?query=up`, returns `success`.
- Every object has `instanceSelector.matchLabels` with `app.kubernetes.io/instance: perses`.
