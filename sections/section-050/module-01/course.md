# Operate Perses Day To Day

A Perses server that is installed and delivering dashboards is the start of the work, not the end. Operators of the platform spend most of their time on four tasks: seeing what state the system is in, keeping a copy of the data that is not in Git, changing the system without an outage, and finding the cause when something stops. This module covers all four with the commands you already have.

Keep one sentence in mind: **a Perses platform has three places to look, and the cause of a problem is in the first one that shows an error: the conditions of the object, the logs of the pod, and the logs of the operator.** Every troubleshooting step in this module walks that list from the object outward.

The module has four parts. **See What The Platform Is Doing** reads conditions, events and logs and finds the metrics endpoint of the server. **Back Up And Restore Perses Data** exports projects and dashboards through the API and restores them. **Change And Upgrade Safely** shows how a change rolls out and in which order to upgrade. **A Troubleshooting Playbook** breaks the platform three ways and fixes each. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Read the conditions of a `Perses`, `PersesDashboard` and `PersesDatasource`, the events of a namespace and the logs of the server and the operator.
- Say which data lives only in the Perses database, and which data can be rebuilt from objects or Git.
- Export a project to a file through the API and restore it onto an empty server.
- Roll out a change to a server, read the rollout and undo the change through the `Perses` resource.
- State a safe order to upgrade the operator, its definitions and the server.
- Use the three places to look to find the cause of a stuck server, a refused dashboard and a dashboard that never arrives.

## Before you start

You need the earlier sections: the operator and the `Perses` resource, dashboards and datasources as custom resources, selectors, and the conditions the operator reports. Delivery with Flux is helpful but not required.

Your playground is a single-node `kind` cluster with the **Perses Operator v0.5.0** and a Perses server (**Perses v0.54.0**) at `http://perses.perses:8080` that uses an `emptyDir` database. The namespaces `payments` and `catalog` exist and are empty. Prometheus and a `tester` pod with `curl` and `jq` run in `observability`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
