# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to read, apply, patch and delete objects in a namespace.
- Read a custom resource and its `.status.conditions`.
- Explain what a ResourceQuota and a NetworkPolicy are.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- Helm 3.22.1, `percli` v0.54.0 on your PATH.
- The Perses Operator v0.5.0 in the namespace `perses-operator`.
- Prometheus and a `tester` pod with `curl` and `jq` in the namespace `observability`.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of the cluster.
- Change one thing at a time and check the result after each change.
- A Perses server answers at `http://<name>.<namespace>:8080` inside the cluster.
  From your machine, run `kubectl -n <namespace> port-forward svc/<name> 8080:8080`
  and use `http://perses.localtest.me:8080`.
