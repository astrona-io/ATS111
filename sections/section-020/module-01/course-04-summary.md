# Summary

A team's dashboards can be Kubernetes objects in the team's namespace. This module showed how the Perses Operator turns those objects into Perses resources, how they find their servers, and how provisioning loads resources when there is no operator.

## What you learned

A `PersesDatasource` is a namespaced object whose `spec.config` holds a Perses datasource: a display name, the `default` flag and a plugin. With an `HTTPProxy`, the Perses server forwards every query, so the URL is the cluster address of Prometheus. The operator copies the datasource into the Perses project named after the namespace and creates that project when it is missing. A `PersesGlobalDatasource` is the cluster-scoped version and becomes a global datasource. The annotation `perses.dev/tags` becomes lower-case Perses tags. The strongest proof of a datasource is a query through `/proxy/projects/<project>/datasources/<name>/`.

A `PersesDashboard` holds the whole dashboard spec under `spec.config`: panels, queries and layouts that refer to panels with `$ref`. Changing the object updates the Perses copy, and deleting the object deletes it. A change made in Perses itself is overwritten on the next reconciliation. Projects stay when their last object is deleted. `instanceSelector` selects `Perses` resources by the labels in their own `metadata.labels`. With no match the reason is `PersesMissing` and the operator retries every minute. When the server refuses a dashboard, the reason is `ValidationFailed`, and the message holds the server's explanation.

Provisioning is a feature of the Perses server: it loads resource files from `provisioning.folders` at start and again at an interval. With the operator, the files come from a ConfigMap mounted outside the reserved path `/etc/perses/provisioning`. Without the operator, the Helm chart's sidecar collects labelled ConfigMaps into that folder. Provisioning has no status and no per-namespace permissions; the custom resources have both. The key facts to remember are these:

- The namespace is the project, and the object is the source of truth.
- `Available=True` proves the copy, not the data; query through the proxy.
- `PersesMissing` means no server matches the selector; `ValidationFailed` means the server refused the dashboard.
- Provisioned dashboards need their `Project` as a file too.

<!-- astrona:playground:destroy -->
