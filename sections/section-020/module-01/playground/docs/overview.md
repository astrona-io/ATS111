# Overview: Declare Dashboards And Datasources In Namespaces (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the Perses Operator and one Perses server, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Helm 3.22.1 and `percli` v0.54.0 on your PATH.
- The **Perses Operator v0.5.0** in the namespace `perses-operator`. It copies `PersesDatasource`, `PersesGlobalDatasource` and `PersesDashboard` objects into Perses.
- A `Perses` resource named `perses` in the namespace `perses`, labelled `app.kubernetes.io/instance: perses`, running **Perses v0.54.0** at `http://perses.perses:8080`.
- Prometheus (`prom/prometheus:v3.15.1`) and a `tester` pod with `curl` and `jq` in the namespace `observability`.
- The empty namespaces `payments` and `catalog`.

## Helpers

Paste these once in each new terminal. `perses_api` sends a GET request to the Perses API from the `tester` pod and pretty-prints the JSON. `show_conditions` prints the conditions of one custom resource. `query_through` runs the Prometheus query `up` through a project's datasource proxy and prints the status.

```sh
perses_api() {
  kubectl -n observability exec deploy/tester -- sh -c "curl -s 'http://perses.perses:8080$1' | jq ."
}
show_conditions() {
  kubectl -n "$1" get "$2" "$3" \
    -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
}
query_through() {
  kubectl -n observability exec deploy/tester -- sh -c \
    "curl -s 'http://perses.perses:8080/proxy/projects/$1/datasources/$2/api/v1/query?query=up' | jq -r .status"
}
```

Use them like this: `perses_api /api/v1/projects`, `show_conditions payments persesdashboard payments-overview`, `query_through payments prometheus`.

To open the Perses user interface, run `kubectl -n perses port-forward svc/perses 8080:8080` in a second terminal and browse to `http://perses.localtest.me:8080`.

## Practice tasks

- Declare a `PersesDatasource` in `catalog` with the URL `http://prometheus.monitoring.svc.cluster.local:9090`. Predict its conditions and the answer of `query_through catalog prometheus` before you look.
- Give a dashboard an `instanceSelector` with a label no `Perses` resource has. Read the reason, then add that label to the `Perses` resource with `kubectl -n perses label perses perses <key>=<value>` and watch the dashboard arrive within a minute.
- Point a layout item at `#/spec/panels/missing` and read the message of the `ValidationFailed` condition.
- Change a dashboard's title in the Perses user interface, then change any annotation on its `PersesDashboard` object. Check which title wins.
- Delete every object in `payments`, then list the Perses projects. Explain why `payments` is still there.
