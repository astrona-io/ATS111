# Run Perses With The Perses Operator

A Perses server is a single Go program that serves dashboards over HTTP and stores them in a database. You can run it as a Deployment you write by hand. Then every change, from a new image to a new configuration file, is a hand-made change to several objects, and nothing tells you when one of them is wrong.

The Perses Operator changes that. An operator is a controller, a program in the cluster that watches objects of some kinds and changes the cluster until it matches them. You declare one `Perses` resource, and the operator creates and updates the Deployment, the Service and the configuration for it. Keep one sentence in mind: **you change the `Perses` resource, and the operator changes everything else.**

The module has three parts. **What The Perses Operator Does** explains the controller, its custom resources and how it is installed with Helm. **The Perses Resource** walks through the fields of the resource and the objects the operator creates from it, including the address the operator uses to reach the server. **Status Conditions And Troubleshooting** shows how to read the `Available` and `Degraded` conditions, the operator log and the events when a server does not run. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain what an operator is and name the four custom resources of the Perses Operator.
- Install the operator with Helm and explain the `certManager.enable` setting.
- Write a `Perses` resource with an image, a file database, storage, resources and an extra volume.
- Say which Deployment or StatefulSet and which Service the operator creates for a `Perses` resource.
- Explain how the operator reaches a Perses server and why `spec.service.name` must not change it.
- Read the `Available` and `Degraded` conditions and explain why `Available` alone does not prove a running server.
- Find the cause of a server that never serves with the conditions, the operator log and the events.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, ConfigMaps, labels, and the commands `kubectl get`, `kubectl apply`, `kubectl describe` and `kubectl logs`. You also need to know what a Perses server is for: it serves dashboards and reads data from datasources such as Prometheus. This module does not teach dashboards; it teaches how the server itself runs.

Your playground is a single-node `kind` cluster with the **Perses Operator v0.5.0** installed with Helm in the namespace `perses-operator`. A `Perses` resource named `perses` in the namespace `perses` runs **Perses v0.54.0**. Prometheus and a `tester` pod with `curl` and `jq` run in the namespace `observability`. Helm and `percli` are on your PATH.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
