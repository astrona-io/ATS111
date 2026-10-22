# Summary

The Perses Operator runs a Perses server from one Kubernetes object. This module showed what the operator builds from that object, how it reaches the server it built, and how to read the status it writes back.

## What you learned

An operator is a controller: it watches custom resources through the API server and reconciles the cluster until it matches them. The Perses Operator adds four kinds in the API group `perses.dev`, version `v1alpha2`: `Perses`, `PersesDatasource`, `PersesDashboard` and the cluster-scoped `PersesGlobalDatasource`. It was installed with its Helm chart. With `certManager.enable=false`, the chart generates its own webhook certificate, and only `v1alpha2` objects can be used.

A `Perses` resource holds the server's image, its complete configuration under `spec.config`, its storage and the usual pod settings. From it the operator creates a ConfigMap, a Service and a workload named after the resource. A file database on `emptyDir` gives a Deployment, and any other storage gives a StatefulSet with a PersistentVolumeClaim. The operator reaches the server at `http://<resource name>.<namespace>.svc.cluster.local:<containerPort>`. That address ignores `spec.service.name`, so renaming the Service cuts the operator off from its own server.

The resource reports two conditions, `Available` and `Degraded`. `Degraded=True` means the operator stopped, and its reason says where, for example `InvalidConfiguration` for a volume mount without a volume. `Available=True` only means the objects were created; it does not wait for the pod. So a check of a server reads the conditions, the operator log in the container `manager`, the Deployment and its pod events, and ends with a real request to the Perses API. The key facts to remember are these:

- Change the `Perses` resource, never the objects the operator created.
- Dashboards and datasources find a server by the labels in the resource's own `metadata.labels`.
- A wrong image tag gives `Available=True` and a pod in `ImagePullBackOff`.
- Fix a resource in place; deleting it deletes the server and its `emptyDir` data.

<!-- astrona:playground:destroy -->
