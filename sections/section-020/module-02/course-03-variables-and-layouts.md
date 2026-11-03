# Variables And Layouts In The Dashboard Spec

A dashboard that has one hard-coded query per panel needs a copy for every job, environment or team it should show. Variables remove the copies: the user picks a value, and every query that uses the variable changes. This part adds a variable to a dashboard in a `PersesDashboard`, uses it in two panels, and checks the result in the Perses API.

## What spec.config holds

The operator does not interpret `spec.config` of a `PersesDashboard`. It copies the block into the Perses dashboard as it is, so the block follows the Perses dashboard specification. Its top-level keys are these:

| Key | What it holds |
| --- | --- |
| `display` | The name shown in the user interface |
| `duration` | The default time range, for example `1h` |
| `refreshInterval` | How often the dashboard reloads its data |
| `variables` | The list of variables |
| `panels` | A map of panel names to panels |
| `layouts` | How panels are placed on a grid, by reference to the panel names |

Every panel is a plugin: a `kind` such as `TimeSeriesChart` or `Markdown` and a `spec` for that kind. A query is a plugin too: `PrometheusTimeSeriesQuery` with a `query` string. Because the operator copies the block, the Perses server is what checks it, and a mistake shows up as `ValidationFailed` on the object.

## Declare a dashboard with a variable

A variable is an entry of the `variables` list. A `ListVariable` offers a list of values, and its values can come from a plugin. The plugin `PrometheusLabelValuesVariable` asks Prometheus for every value of a label, here the label `job`. A query uses the variable with a dollar sign and its name.

The commands below need the `PersesDatasource` `prometheus` in the namespace `payments`, set as the project's default, as the previous part declared. If it is missing, apply the file for it again first.

Save this as `persesdashboard-payments-jobs.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: jobs
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Jobs
    duration: 1h
    refreshInterval: 30s
    variables:
      - kind: ListVariable
        spec:
          name: job
          display:
            name: Job
          allowAllValue: false
          allowMultiple: false
          plugin:
            kind: PrometheusLabelValuesVariable
            spec:
              labelName: job
    panels:
      up:
        kind: Panel
        spec:
          display:
            name: Target up
          plugin:
            kind: TimeSeriesChart
            spec: {}
          queries:
            - kind: TimeSeriesQuery
              spec:
                plugin:
                  kind: PrometheusTimeSeriesQuery
                  spec:
                    query: up{job="$job"}
      samples:
        kind: Panel
        spec:
          display:
            name: Scraped samples
          plugin:
            kind: TimeSeriesChart
            spec: {}
          queries:
            - kind: TimeSeriesQuery
              spec:
                plugin:
                  kind: PrometheusTimeSeriesQuery
                  spec:
                    query: scrape_samples_scraped{job="$job"}
    layouts:
      - kind: Grid
        spec:
          display:
            title: Health
          items:
            - x: 0
              y: 0
              width: 12
              height: 6
              content:
                $ref: "#/spec/panels/up"
            - x: 12
              y: 0
              width: 12
              height: 6
              content:
                $ref: "#/spec/panels/samples"
```

Apply it:

```sh
kubectl apply -f persesdashboard-payments-jobs.yaml
```

Then check the result:

```sh
kubectl -n payments get persesdashboard jobs \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards/jobs | jq -r ".spec.variables[].spec.name, (.spec.layouts[0].spec.items | length)"'
```

`Available` is `True`. The API returns the variable name `job` and the number of layout items, `2`. The variable list asks the datasource for the values of the label `job`, so the user interface shows a drop-down with the job names Prometheus knows.

## Text variables and the order of variables

A `TextVariable` holds one value that the user types, with a default in `value`, and is used the same way: `$name` in a query. When variables depend on each other, for example a `namespace` variable and a `pod` variable that filters by the chosen namespace, the later variable uses the earlier one in its own matchers. Perses works out the order from the references, and a loop of references is an error on the dashboard.

A variable can also be declared once for a project or for the whole server, as a Perses variable resource, and then used by every dashboard of that project. The operator in version 0.5.0 manages dashboards and datasources only. Project variables are not custom resources, so they come from provisioning or from `percli`.

## Layouts

A layout is a grid of 24 columns. Each item has an `x` and `y` position, a `width` and a `height`, and a `content` that refers to a panel with a JSON reference. A reference to a panel that does not exist is the most common cause of `ValidationFailed`, and the message names the reference. A layout can also group items under a collapsible title, which is how long dashboards stay readable.

You can now describe the keys of `spec.config`, add a variable and check it in the API. The open question is how to see what a change will do before it is applied.

## Common pitfalls

> [!WARNING]
> - **Using the variable name in the query but not in `variables`.** The query then shows an unresolved name and returns nothing.
> - **Referencing a panel by a different name than its key.** The key under `panels` is the name the reference must use.
> - **Expecting the operator to check the panel plugins.** The Perses server checks them. Read the conditions after an apply.
> - **Looking for project variables as custom resources.** Version 0.5.0 of the operator does not have such a kind.
