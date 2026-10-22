# Declare Dashboards And Datasources In Namespaces

A team that runs an application in a namespace also wants its dashboards there: in the same repository, reviewed the same way, deleted with the application. The Perses Operator makes that possible. A `PersesDatasource` or a `PersesDashboard` is a Kubernetes object in the team's namespace, and the operator copies it into the Perses project with the same name.

Keep one sentence in mind: **the namespace is the project, and the object is the source of truth.** The operator creates the project when it is missing, writes the dashboard or datasource into it, and overwrites the Perses copy whenever it reconciles the object.

The module has three parts. **Datasources As Custom Resources** declares a project datasource and a global datasource and proves them with a real query. **Dashboards As Custom Resources** declares a dashboard, shows how `instanceSelector` picks the servers, and follows a change and a delete into Perses. **Provisioning Without The Operator** loads resources from files, the way a Perses server without the operator does it. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Write a `PersesDatasource` with an HTTP proxy to Prometheus, and a `PersesGlobalDatasource`.
- Write a `PersesDashboard` whose `spec.config` holds a panel, a query and a layout.
- Explain how a namespace becomes a Perses project, and what deleting objects leaves behind.
- Use `instanceSelector` and say which labels it reads.
- Read the reasons `PersesMissing`, `PersesConnectionFailed` and `ValidationFailed`.
- Prove a datasource with a query through the Perses datasource proxy.
- Load a project and a dashboard into Perses from files with provisioning.

## Before you start

You need Kubernetes basics: namespaces, labels, `kubectl apply`, `kubectl get` and `kubectl delete`. You also need to know what a Perses dashboard is: panels that run queries against a datasource, arranged by a layout. This module does not teach how to design a dashboard; it teaches how to deliver one as a Kubernetes object.

Your playground is a single-node `kind` cluster with the **Perses Operator v0.5.0** and a `Perses` resource named `perses` in the namespace `perses`, which runs **Perses v0.54.0** with the label `app.kubernetes.io/instance: perses`. Prometheus runs in the namespace `observability`, next to a `tester` pod with `curl` and `jq`. The namespaces `payments` and `catalog` exist and are empty.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
