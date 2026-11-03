# Limit And Harden The Shared Server

Giving each team rights in its own namespace stops one team from changing another team's dashboards. It does not stop a team from creating thousands of dashboards, it does not stop other workloads from calling the Perses server, and it does not say what the operator itself is allowed to do. This module covers those three limits and the settings of the server that reduce what an API call can change.

Keep one sentence in mind: **rights say what a team may do, and limits say how much of it, from where, and with which identity.** Each part adds one of the limits and proves it with a command that fails the way it should.

The module has four parts. **Cap What A Team Can Create** puts a quota on the number of dashboards. **Restrict Who Can Call The Server** adds a network policy that lets in only the operator and the tools that need the server. **Read-Only Mode And Server Authentication** shows what the server settings change for the operator and for users. **Least Privilege For The Operator** reads the rights of the operator itself. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Write a ResourceQuota that caps the number of `PersesDashboard` or `PersesDatasource` objects in a namespace, and read its usage.
- Say what a rejected object looks like to `kubectl` and to Flux.
- Write a NetworkPolicy for the Perses namespace that allows the operator and named namespaces and nothing else, and name what it does not enforce on a cluster without a policy engine.
- Explain what read-only mode does to the operator, and what turning authentication on changes.
- Read the ClusterRole of the operator and test what its ServiceAccount may do.

## Before you start

You need the previous module in this section: a namespace per team, Roles and RoleBindings, and impersonation with `--as`. You also need the basic idea of a NetworkPolicy: a rule that says which pods may send traffic to which pods.

Your playground is a single-node `kind` cluster with the **Perses Operator v0.5.0** and a Perses server (**Perses v0.54.0**) at `http://perses.perses:8080`. The namespaces `payments` and `catalog` exist and each holds a ServiceAccount `<team>-ci` with no permissions. Prometheus and a `tester` pod with `curl` and `jq` run in `observability`. Your own `kubectl` user is a cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
