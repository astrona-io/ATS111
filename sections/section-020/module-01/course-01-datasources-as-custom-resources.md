# Datasources As Custom Resources

A dashboard without a datasource shows empty panels. So the first object a team declares is the datasource: the connection from Perses to the system that holds the data, here Prometheus. This part declares one datasource for a team and one for the whole server, proves each with a real query, and shows which Perses objects the operator creates on the way.

## A datasource for one team

A `PersesDatasource` is a namespaced custom resource. The operator copies it into the Perses project that has the same name as its namespace, and creates that project first if it is missing. Its `spec.config` holds the same fields as a Perses datasource: a display name, whether it is the project's default, and a plugin with the connection details.

The connection below uses an HTTP proxy. With a proxy, the browser never talks to Prometheus directly: it sends each query to the Perses server, and the Perses server forwards it to the URL in the datasource. That is why an address that only works inside the cluster, such as `http://prometheus.observability.svc.cluster.local:9090`, is the right choice.

<!-- astrona:playground:renew -->

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

`Available` is `True` with reason `Reconciled`. The `instanceSelector` chose which Perses servers receive the datasource: every `Perses` resource whose own `metadata.labels` match. Your server carries `app.kubernetes.io/instance: perses`, so it matches.

## What the operator created in Perses

The condition says the operator succeeded. The Perses server is the place where that must be true. Ask the Perses API, from the `tester` pod, for its projects and for the datasource:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects | jq -r ".[].metadata.name"'
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/payments/datasources/prometheus | jq .spec'
```

The first command lists the project `payments`, which the operator created from the namespace name. The second prints the datasource spec as Perses stores it: the same `display`, `default` and `plugin` that you wrote under `spec.config`.

A datasource that exists can still point at the wrong address. Prove it with a query. Perses forwards any request under `/proxy/projects/<project>/datasources/<name>/` to the datasource, so a Prometheus API call goes through it:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s "http://perses.perses:8080/proxy/projects/payments/datasources/prometheus/api/v1/query?query=up" | jq .status'
```

The answer is `"success"`, from Prometheus, through Perses. This query is the strongest check of a datasource, because it uses the same path a dashboard panel uses.

## A datasource for every project

Some datasources belong to everyone: one central Prometheus, one Loki. A `PersesGlobalDatasource` is the cluster-scoped version of the same object. It has no namespace, so the operator creates a global datasource in Perses instead of a project one, and every project can use it.

Save this as `persesglobaldatasource-prometheus-central.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesGlobalDatasource
metadata:
  name: prometheus-central
  annotations:
    perses.dev/tags: "shared,metrics"
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Central Prometheus
    default: false
    plugin:
      kind: PrometheusDatasource
      spec:
        proxy:
          kind: HTTPProxy
          spec:
            url: http://prometheus.observability.svc.cluster.local:9090
```

Apply it:

```sh
kubectl apply -f persesglobaldatasource-prometheus-central.yaml
```

Then check the result with `curl -s http://perses.perses:8080/api/v1/globaldatasources/prometheus-central` from the `tester` pod. The answer holds the datasource, and its `metadata.tags` lists `shared` and `metrics`. The operator reads the annotation `perses.dev/tags` on any of its custom resources, lower-cases the values and stores them as Perses tags, which the user interface can filter on.

When a datasource needs credentials, such as a password for Prometheus behind basic authentication, the custom resource has a `client` field that names a Kubernetes Secret. The operator then creates a Perses secret named after the datasource with the suffix `-secret`, in the same project, and the datasource refers to it under `spec.config.plugin.spec.proxy.spec.secret`. The operator only watches Secrets labelled `perses.dev/watch: "true"` for changes, so label every Secret you reference that way.

You can now declare a project datasource and a global datasource, find them in Perses, and prove them with a query. The datasource is only half of a team's work; the open question is how the dashboard that uses it reaches Perses.

## Common pitfalls

> [!WARNING]
> - **Pointing the proxy at an address only your browser can reach.** With `HTTPProxy`, the Perses server makes the request, so use the cluster address of Prometheus.
> - **Taking `Available=True` as proof the datasource works.** It proves the copy reached Perses, not that Prometheus answers. Send a query through `/proxy/`.
> - **Expecting a `PersesGlobalDatasource` in a project.** It becomes a global datasource; look under `/api/v1/globaldatasources`.
> - **Forgetting the watch label on a referenced Secret.** Without `perses.dev/watch: "true"`, a changed password does not trigger a new sync.
