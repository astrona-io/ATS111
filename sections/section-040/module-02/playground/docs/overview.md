# Overview: Limit And Harden The Shared Server (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the operator and a shared Perses server, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it, as a cluster administrator.
- Helm 3.22.1 and `percli` v0.54.0 on your PATH.
- The **Perses Operator v0.5.0** in `perses-operator`, and a Perses server at `http://perses.perses:8080`.
- The namespaces `payments` and `catalog`, each with a ServiceAccount `<team>-ci` that has no permissions.
- Prometheus and a `tester` pod with `curl` and `jq` in `observability`.

## Practice tasks

- Cap `payments` at two dashboards and one datasource, then create three of each and read the errors.
- Lower a quota below the current count and see that nothing is deleted.
- Write a NetworkPolicy for the namespace `perses` and test it with a pod in `catalog`. Decide from the result whether the cluster enforces policies.
- Remove `perses-operator` from the policy and watch a dashboard fail to reach the server.
- Start a server with `security.readonly: true` and send a dashboard to it.
- Run `kubectl explain perses.spec.client --api-version=perses.dev/v1alpha2 --recursive` and list the authentication options.
- Print the rules of the operator's ClusterRole and test three actions with `kubectl auth can-i --as`.
- Check that `payments-ci` cannot edit anything in `perses-operator`.
