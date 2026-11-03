# Summary

Team resources do not only need to exist. They must reach the right Perses server, expose the right data, hold dashboards that adapt to the user, and change without surprise. This module covered each of those steps.

## What you learned

The field `instanceSelector` is a label selector over `Perses` resources. The operator reads the labels in the resource's own `metadata.labels`, keeps the matching resources that are available, and sends the object to each. With `matchLabels` every pair must match, and with `matchExpressions` every rule must match. An object with no selector goes to every server. Narrowing a selector does not remove the copy from a server that no longer matches, so you check the old server after the change.

A Prometheus datasource reaches Prometheus through a proxy or with a direct URL. The proxy forwards queries from the Perses server and is the only form that can restrict them. The list `allowedEndpoints` names the paths and methods the proxy forwards, and a request outside the list is refused. A limit is only proved when every endpoint a dashboard needs works and an endpoint outside the list does not.

The block `spec.config` of a dashboard is the Perses dashboard specification, copied as it is. It holds the display name, the duration, the variables, the panels and the layouts. A variable such as a list of label values is used in queries with a dollar sign, and layouts refer to panels by a JSON reference. The Perses server, not the operator, validates the block.

An object passes two checks. The Kubernetes API server checks the schema at apply time, which a server-side dry run shows. The Perses server checks the dashboard content later and reports `ValidationFailed` in the conditions. `kubectl diff` shows what an apply would change, a staging server finds Perses-level errors early, and `deletionTimestamp` and `finalizers` explain an object that does not disappear. The key facts to remember are these:

- Selectors read the labels of the `Perses` resource.
- `allowedEndpoints` limits what a datasource proxy forwards.
- The Perses server validates `spec.config`.
- A dry run checks the schema, not the panels.
- Do not remove a finalizer before you know why it is there.

<!-- astrona:playground:destroy -->
