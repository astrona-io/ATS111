# Overview: Operate Perses Day To Day (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the operator and a Perses server, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Helm 3.22.1 and `percli` v0.54.0 on your PATH.
- The **Perses Operator v0.5.0** in `perses-operator`, and a Perses server at `http://perses.perses:8080` with an `emptyDir` database.
- The empty namespaces `payments` and `catalog`.
- Prometheus and a `tester` pod with `curl` and `jq` in `observability`.

## Practice tasks

- Read the conditions of the server, the events of the `perses` namespace and the logs of the server and the operator.
- Ask the server for `/metrics` and decide whether your version exposes it.
- Create a project and a dashboard through the API, export them to a ConfigMap, delete the project and restore it.
- Raise the memory limit of the server through the `Perses` resource and watch the rollout.
- Set an image tag that does not exist and check that the old pod keeps answering.
- Break a second server three ways: the image, a dashboard reference and a selector. Fix each by following the order of the playbook.
- Run `percli --help` and list the commands that read and write resources.
