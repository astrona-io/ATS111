# Overview: Run Perses With The Perses Operator (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Perses Operator and runs a Perses server from a `Perses` resource, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Helm 3.22.1 and `percli` v0.54.0 on your PATH.
- The **Perses Operator v0.5.0** in the namespace `perses-operator`, installed with Helm with `certManager.enable=false`. The operator is a controller: it watches the `Perses` resource and creates the server's objects from it.
- A `Perses` resource named `perses` in the namespace `perses`, with the label `app.kubernetes.io/instance: perses`, the image `docker.io/persesdev/perses:v0.54.0`, a file database on `emptyDir` and port `8080`. The operator created a Deployment, a Service and a ConfigMap named after it.
- Prometheus (`prom/prometheus:v3.15.1`) and a `tester` pod with `curl` and `jq` in the namespace `observability`.

## Helpers

Paste these once in each new terminal. `show_conditions` prints the two status conditions of the `Perses` resource. `server_answers` sends one request to the Perses API from the `tester` pod and prints the HTTP status code. `operator_log` prints the last lines of the operator's log.

```sh
show_conditions() {
  kubectl -n perses get perses perses \
    -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
}
server_answers() {
  kubectl -n observability exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' http://perses.perses:8080/api/v1/projects
}
operator_log() {
  kubectl -n perses-operator logs deploy/perses-operator-controller-manager -c manager --tail=30
}
```

Use them like this: `show_conditions`, `server_answers`, `operator_log`.

To open the Perses user interface, run `kubectl -n perses port-forward svc/perses 8080:8080` in a second terminal and browse to `http://perses.localtest.me:8080`.

## Practice tasks

- Set `spec.replicas` to `2` with `kubectl -n perses patch perses perses --type merge -p '{"spec":{"replicas":2}}'`. Predict how many pods appear, and what happens to the dashboards each pod holds on its own `emptyDir`.
- Remove `spec.storage` from the resource. Predict whether the operator now creates a Deployment or a StatefulSet, then check with `kubectl -n perses get deployments,statefulsets,pvc`.
- Set `spec.service.name` to `perses-ui`. Check which Services exist afterwards, and think about the address the operator uses to reach the server.
- Delete the Deployment `perses` by hand and watch how fast the operator creates it again.
- Set `logLevel` to `trace` and read the server log with `kubectl -n perses logs deploy/perses`.
