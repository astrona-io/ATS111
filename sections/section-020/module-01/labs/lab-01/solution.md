# Solution: Give Two Teams Their Own Dashboards

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the two Perses projects, the four objects `Available` and in Perses with the right names, a query through each datasource, and the `instanceSelector` on every object.

## Step 1: Write the payments objects

One file can hold both objects of a team, separated by `---`. Save this as `perses-payments.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDatasource
metadata:
  name: prometheus
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Prometheus
    default: true
    plugin:
      kind: PrometheusDatasource
      spec:
        proxy:
          kind: HTTPProxy
          spec:
            url: http://prometheus.observability.svc.cluster.local:9090
---
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: payments-overview
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Payments Overview
    duration: 1h
    panels:
      up:
        kind: Panel
        spec:
          display:
            name: Targets Up
          plugin:
            kind: TimeSeriesChart
            spec: {}
          queries:
            - kind: TimeSeriesQuery
              spec:
                plugin:
                  kind: PrometheusTimeSeriesQuery
                  spec:
                    query: up
    layouts:
      - kind: Grid
        spec:
          display:
            title: Health
          items:
            - x: 0
              y: 0
              width: 12
              height: 6
              content:
                $ref: "#/spec/panels/up"
```

Apply it:

```sh
kubectl apply -f perses-payments.yaml
```

## Step 2: Write the catalog objects

The catalog file is the same with three changes: the namespace `catalog`, the dashboard name `catalog-overview`, and the display name `Catalog Overview`. Save this as `perses-catalog.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDatasource
metadata:
  name: prometheus
  namespace: catalog
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Prometheus
    default: true
    plugin:
      kind: PrometheusDatasource
      spec:
        proxy:
          kind: HTTPProxy
          spec:
            url: http://prometheus.observability.svc.cluster.local:9090
---
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: catalog-overview
  namespace: catalog
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Catalog Overview
    duration: 1h
    panels:
      up:
        kind: Panel
        spec:
          display:
            name: Targets Up
          plugin:
            kind: TimeSeriesChart
            spec: {}
          queries:
            - kind: TimeSeriesQuery
              spec:
                plugin:
                  kind: PrometheusTimeSeriesQuery
                  spec:
                    query: up
    layouts:
      - kind: Grid
        spec:
          display:
            title: Health
          items:
            - x: 0
              y: 0
              width: 12
              height: 6
              content:
                $ref: "#/spec/panels/up"
```

Apply it:

```sh
kubectl apply -f perses-catalog.yaml
```

## Step 3: Check the objects and Perses

```sh
for team in payments catalog; do
  kubectl -n "$team" get persesdatasource,persesdashboard \
    -o jsonpath='{range .items[*]}{.kind}/{.metadata.name}: {.status.conditions[?(@.type=="Available")].status}{"\n"}{end}'
done
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects | jq -r ".[].metadata.name"'
```

All four objects print `True`, and the project list holds `payments` and `catalog`. The operator created both projects from the namespace names.

## Step 4: Prove each datasource with a query

```sh
for team in payments catalog; do
  kubectl -n observability exec deploy/tester -- sh -c \
    "curl -s 'http://perses.perses:8080/proxy/projects/$team/datasources/prometheus/api/v1/query?query=up' | jq -r .status"
done
```

Both lines print `success`: Prometheus answered through each team's datasource.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create the dashboards with `percli apply` | They appear in Perses, but there is no object to manage them; the grader checks the custom resources |
| Leave out `instanceSelector` | The objects sync today, and go to every future Perses server in the cluster too; the grader requires the selector |
| Use `directUrl` with `localhost:9090` | The browser would query its own machine; with a proxy, the Perses server reaches Prometheus inside the cluster |

## Common mistakes

- Using the wrong `apiVersion`. Without cert-manager only `perses.dev/v1alpha2` works.
- Writing the dashboard spec directly under `spec`. The dashboard content belongs under `spec.config`.
