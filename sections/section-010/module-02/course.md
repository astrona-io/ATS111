# Configure The Perses Server

A Perses server that runs is not yet a server you can operate. It also has to keep its data when a pod restarts, accept the configuration your organisation needs, fit the resources of the node, and talk to the operator in a way both sides trust. All of that is set in the `Perses` resource, and a wrong value shows up as a pod that restarts, data that disappears or a server that refuses to start.

The module has four parts. **Persistent Storage And Workload Kinds** moves the database from the pod to a PersistentVolumeClaim and shows how that changes the workload. **The Server Configuration In spec.config** explains the sections of the Perses configuration file and how to read the configuration a running server uses. **Pod Settings And Replicas** covers resources, scheduling, probes, extra labels and why more than one replica needs more than a file database. **TLS, Provisioning And The Operator Client** covers the fields that protect the connection to the server and the way the operator authenticates to it. A graded lab follows the first part.

## Learning objectives

After this module you can:

- Declare a `Perses` resource with a PersistentVolumeClaim and prove that a project survives the deletion of the pod.
- Say which workload the operator creates for each storage setting and what it names the pods.
- Name the main sections of the Perses server configuration and read the configuration a running server uses from its API.
- Change the server configuration through `spec.config` and recognise a configuration the server refuses.
- Find any field of the `Perses` resource with `kubectl explain` and set resources, labels, scheduling and probes.
- Explain why a second replica with a file database does not give a highly available server.
- Name the fields for server TLS, provisioning and the operator client, and say what each one protects.

## Before you start

You need the basics of the `Perses` resource: that the operator creates a workload, a Service and a ConfigMap from it, and that you change the resource and never the objects it creates. You also need Kubernetes storage basics: what a PersistentVolumeClaim and a StorageClass are.

Your playground is a single-node `kind` cluster with the **Perses Operator v0.5.0** installed in the namespace `perses-operator` and a `Perses` resource named `perses` in the namespace `perses`, running **Perses v0.54.0**. Prometheus and a `tester` pod with `curl` and `jq` run in the namespace `observability`. The `kind` cluster has a default StorageClass, so a PersistentVolumeClaim without a class name is bound on its own.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
