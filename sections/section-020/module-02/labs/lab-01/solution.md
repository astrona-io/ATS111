# Solution: Send A Dashboard To Staging And Limit Its Datasource

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks five things: the label on the production server, the conditions of the two objects, where the dashboard exists, the query through the datasource, and the list of allowed paths.

## Step 1: Label production

The staging server carries `env=staging`. Give the production server a label that differs:

```sh
kubectl -n perses label perses perses env=production
```

## Step 2: Write the two objects

The selector uses the label of the staging server. Save this as `team-resources.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: checkout
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      env: staging
  config:
    display:
      name: Checkout
    duration: 1h
    panels: {}
    layouts: []
---
apiVersion: perses.dev/v1alpha2
kind: PersesDatasource
metadata:
  name: prometheus
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      env: staging
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
            allowedEndpoints:
              - endpointPattern: /api/v1/query
                method: GET
              - endpointPattern: /api/v1/query_range
                method: GET
              - endpointPattern: /api/v1/labels
                method: GET
              - endpointPattern: /api/v1/label/([a-zA-Z0-9_-]+)/values
                method: GET
              - endpointPattern: /api/v1/series
                method: GET
```

Apply it:

```sh
kubectl apply -f team-resources.yaml
```

## Step 3: Check the conditions and the servers

```sh
kubectl -n payments get persesdashboard checkout -o jsonpath='{.status.conditions[?(@.type=="Available")].status}{"\n"}'
kubectl -n payments get persesdatasource prometheus -o jsonpath='{.status.conditions[?(@.type=="Available")].status}{"\n"}'
```

Both print `True` after a short time. Then ask each server for the dashboards of the project `payments`:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  "curl -s http://staging.perses-staging:8080/api/v1/projects/payments/dashboards | jq -r '.[].metadata.name'"
kubectl -n observability exec deploy/tester -- sh -c \
  "curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards | jq -r '.[].metadata.name'"
```

The first prints `checkout`. The second prints nothing, or an error body, because production has no such dashboard.

## Step 4: Query through the datasource

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  "curl -s 'http://staging.perses-staging:8080/proxy/projects/payments/datasources/prometheus/api/v1/query?query=up' | jq -r .status"
```

The answer is `success`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| No selector on the dashboard | Both servers receive it, and production shows an unfinished dashboard |
| Selecting with `app.kubernetes.io/instance: staging` | Works, but the task asks for the `env` label, and the grader reads that |
| Leaving out `allowedEndpoints` | The datasource works, and the limit is not set |

## Common mistakes

- Putting the label on the dashboard instead of on the server. The selector reads the labels of the `Perses` resource.
- Applying the objects before labelling production. Nothing breaks, but a later selector change would be needed.
- Reading `Available=True` and stopping. Ask each server what it holds.
