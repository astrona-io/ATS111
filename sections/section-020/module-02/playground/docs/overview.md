# Overview: Route And Shape Team Resources (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Perses Operator and runs a Perses server, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Helm 3.22.1 and `percli` v0.54.0 on your PATH.
- The **Perses Operator v0.5.0** in the namespace `perses-operator`.
- A `Perses` resource named `perses` in the namespace `perses`, serving at `http://perses.perses:8080`.
- The namespaces `payments` and `catalog`, both empty.
- Prometheus (`prom/prometheus:v3.15.1`) and a `tester` pod with `curl` and `jq` in the namespace `observability`.
- The file `manifests/perses-staging.yaml` in the playground directory describes a second server, `staging` in the namespace `perses-staging`. It is not applied. The module walks through creating it.

## Helpers

Paste these once in each new terminal. `projects` prints the project names of the server at the address you give. `dashboards` prints the dashboard names of one project on that server.

```sh
projects() {
  kubectl -n observability exec deploy/tester -- sh -c "curl -s http://$1:8080/api/v1/projects | jq -r '.[].metadata.name'"
}
dashboards() {
  kubectl -n observability exec deploy/tester -- sh -c "curl -s http://$1:8080/api/v1/projects/$2/dashboards | jq -r '.[].metadata.name'"
}
```

Use them like this: `projects perses.perses`, `dashboards perses.perses payments`.

## Practice tasks

- Label `perses` with `env=production`, run `staging` with `env=staging`, and send a dashboard to each with `matchLabels`.
- Write one dashboard with a `matchExpressions` rule `env In (production, staging)` and find it on both servers.
- Remove the selector from a dashboard and see which servers receive it.
- Change the selector of a dashboard from production to staging and check whether the production server still has it.
- Declare a datasource with `allowedEndpoints`, ask for an allowed and a not allowed path, and compare the HTTP status.
- Remove `/api/v1/query_range` from the list and look at what a time series chart does.
- Add a `ListVariable` to a dashboard, then read it back from the API.
- Run `kubectl apply --dry-run=server --validate=strict` and `kubectl diff` on a file with a misspelled field.
