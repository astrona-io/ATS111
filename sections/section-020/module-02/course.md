# Route And Shape Team Resources

A team's dashboards and datasources are only useful when they reach the right Perses server, in the right form, and can be changed without surprises. Real clusters often run more than one Perses server, for example one for staging and one for production, and teams need datasources that expose no more of a data source than they must.

The module has four parts. **Several Servers And Selectors** runs a second Perses server and routes a dashboard to one server or to both with label selectors. **Datasource Proxy Settings** limits which endpoints of Prometheus a datasource lets through. **Variables And Layouts In The Dashboard Spec** shows the parts of `spec.config` that make one dashboard serve many cases. **Preview And Change Safely** covers the commands that show what an apply will change and how deletion behaves. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Run two Perses servers in one cluster and label them so that selectors can tell them apart.
- Write an `instanceSelector` with `matchLabels` and with `matchExpressions`, and predict which servers receive an object.
- Limit a datasource to the Prometheus endpoints a team needs with `allowedEndpoints`, and prove a query through it.
- Explain the difference between the proxy URL and a direct URL of a Prometheus datasource.
- Add variables to a dashboard in `spec.config` and use them in a query.
- Preview a change with a server-side dry run and a diff, and read the metadata that shows a deletion in progress.

## Before you start

You need to know how a `PersesDatasource` and a `PersesDashboard` are written, what `instanceSelector` does, and how a namespace becomes a Perses project. This module builds on those basics and does not repeat them.

Your playground is a single-node `kind` cluster with the **Perses Operator v0.5.0** and a `Perses` resource named `perses` in the namespace `perses`, running **Perses v0.54.0**. The namespaces `payments` and `catalog` exist and are empty. Prometheus and a `tester` pod with `curl` and `jq` run in the namespace `observability`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
