# Datasource Proxy Settings

A Prometheus datasource gives whoever can use a dashboard the power to send queries to Prometheus. With the default proxy settings that power can be wider than the team needs. This part reads the proxy settings of a Prometheus datasource, limits it to the endpoints a dashboard uses, and proves the limit with a real query.

## Proxy and direct access

A Prometheus datasource has two ways to reach Prometheus. With a proxy, the browser sends each query to the Perses server at the path `/proxy/projects/<project>/datasources/<name>/...`, and the server forwards it to the URL in the datasource. The user's browser never needs to reach Prometheus, so an address that only works inside the cluster is fine. With a direct URL, the browser sends the query to Prometheus itself, which needs an address the browser can reach and a Prometheus that allows cross-origin requests.

The proxy is the better default for cluster-internal data sources, and it is also the only form that can limit and change what is sent. Its settings are these:

| Field | What it sets |
| --- | --- |
| `url` | The base URL of Prometheus that the Perses server calls |
| `allowedEndpoints` | A list of path patterns and HTTP methods the proxy may forward; anything else is refused |
| `headers` | Extra HTTP headers the proxy adds to every request |
| `secret` | The name of a Perses secret with credentials, for a Prometheus that needs authentication |

The `url` and the `allowedEndpoints` are the two fields that matter in most clusters. Print the schema from the cluster to see every member on your version:

<!-- astrona:playground:renew -->

```sh
kubectl explain persesdatasource.spec.config --api-version=perses.dev/v1alpha2
```

## Declare a datasource with a limit

The datasource below allows the queries a dashboard needs: instant queries and range queries, label names, label values and series for the variable lists. Each entry has a path pattern and a method. A path pattern is a regular expression for the part of the path after the base URL.

Save this as `persesdatasource-payments-prometheus.yaml`:

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
kubectl apply -f persesdatasource-payments-prometheus.yaml
```

Then check the result:

```sh
kubectl -n payments get persesdatasource prometheus \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
```

`Available` is `True`. The server holds the datasource with its list of allowed endpoints.

## Prove the limit

An allowed query works. Ask the server for the instant query `up` through the datasource:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  "curl -s 'http://perses.perses:8080/proxy/projects/payments/datasources/prometheus/api/v1/query?query=up' | jq -r .status"
```

The answer is `success`. Now ask for an endpoint that is not in the list, the Prometheus build information, and print the HTTP status:

```sh
kubectl -n observability exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
  http://perses.perses:8080/proxy/projects/payments/datasources/prometheus/api/v1/status/buildinfo
```

The proxy does not forward the request, so the status is not `200`. Without a list, anyone who can reach the server could call every Prometheus endpoint that the default settings allow, and you have not decided which ones that is. The list works by allowing what is needed and refusing everything else.

## Change the list and watch the effect

Edit the file, remove the entry for `/api/v1/query_range`, and apply it again. Range queries are what time series charts use, so charts that use this datasource stop drawing, while instant queries still work. Add the entry back and apply the file again before you go on. The effect shows why a list must be tested with a real dashboard and not only with `up`.

## The datasource for every project

The same settings exist in a `PersesGlobalDatasource`, which is cluster-scoped and serves every project. A global datasource is the place for a shared Prometheus, and the place where the `allowedEndpoints` list protects the most users at once. Teams that need something different declare their own `PersesDatasource` in their namespace, and a project-level datasource with the same name takes precedence for that project.

You can now explain proxy and direct access, limit what a proxy forwards, and prove the limit. The open question is how a dashboard uses the data it is allowed to read.

## Common pitfalls

> [!WARNING]
> - **Testing a limit with one query.** A chart uses range queries and a variable uses label values. Test every endpoint a dashboard needs.
> - **Writing a path pattern without escaping.** The pattern is a regular expression, so an unescaped dot matches any character.
> - **Using a direct URL for an address that only works in the cluster.** The browser cannot reach it.
> - **Leaving the list out.** The proxy then forwards what its defaults allow, and you have not decided what a team may call.

## Your mission: Send A Dashboard To Staging And Limit Its Datasource

You can now route an object to one server and limit what a datasource proxy forwards. The graded lab runs a production and a staging server and asks for a dashboard that only staging receives and a datasource that allows only the queries a dashboard needs.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-111-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-111-lab-020-02
astrona start ats-111-playground-020-02
```
