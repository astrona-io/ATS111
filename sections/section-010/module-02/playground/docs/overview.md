# Overview: Configure The Perses Server (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Perses Operator and runs a Perses server from a `Perses` resource, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster with a default StorageClass. `kubectl` is already pointed at it.
- Helm 3.22.1 and `percli` v0.54.0 on your PATH.
- The **Perses Operator v0.5.0** in the namespace `perses-operator`.
- A `Perses` resource named `perses` in the namespace `perses`, with a file database on `emptyDir`, serving at `http://perses.perses:8080`.
- Prometheus (`prom/prometheus:v3.15.1`) and a `tester` pod with `curl` and `jq` in the namespace `observability`.

## Helpers

Paste these once in each new terminal. `server_config` prints the public configuration of the server at the address you give. `project_names` prints the names of its projects. `show_conditions` prints the conditions of a `Perses` resource in the namespace you give.

```sh
server_config() {
  kubectl -n observability exec deploy/tester -- curl -s "http://$1:8080/api/config" | jq .
}
project_names() {
  kubectl -n observability exec deploy/tester -- sh -c "curl -s http://$1:8080/api/v1/projects | jq -r '.[].metadata.name'"
}
show_conditions() {
  kubectl -n "$1" get perses "$2" \
    -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
}
```

Use them like this: `server_config perses.perses`, `project_names perses.perses`, `show_conditions perses perses`.

## Practice tasks

- Run the `keep` server from the module with a `pvcTemplate`. Create a project, delete the pod `keep-0`, and list the projects again.
- Run the same steps against the server `perses`, which uses `emptyDir`. Compare the result.
- Print the volume mounts of the StatefulSet `keep` and match the path with `config.database.file.folder`.
- Set `ephemeral_dashboard.enable: true` on a server and read it back with `server_config`.
- Set a value the server cannot parse and find the cause in the pod log, not in the conditions.
- Run `kubectl explain perses.spec --api-version=perses.dev/v1alpha2 --recursive` and pick three fields you have not used.
- Scale `perses` to two replicas and ask for the projects several times to see the two separate databases.
