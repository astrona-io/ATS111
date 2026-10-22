# Dashboards As Custom Resources

With a datasource in place, a team can declare the dashboard that reads it. A `PersesDashboard` is the dashboard as a Kubernetes object: change the object and Perses changes, delete it and Perses forgets it. This part declares a dashboard, follows a change and a delete into Perses, and shows the two ways a dashboard fails to arrive: no server matches its selector, or the server refuses it.

## A dashboard in the team's namespace

A `PersesDashboard` puts the complete Perses dashboard spec under `spec.config`: a display name, a time range, the panels with their queries, and the layout that places the panels. The operator copies that spec into the project named after the namespace. The dashboard below has one panel, a time series chart of the Prometheus query `up`, and one grid layout that refers to the panel by a JSON reference, `#/spec/panels/up`.

The commands below need the `PersesDatasource` `prometheus` in the namespace `payments`, set as the project's default; the panel does not name a datasource, so Perses uses the default one.

<!-- astrona:playground:renew -->

Save this as `persesdashboard-payments-overview.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: payments-overview
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Payments Overview
    duration: 1h
    panels:
      up:
        kind: Panel
        spec:
          display:
            name: Targets Up
          plugin:
            kind: TimeSeriesChart
            spec: {}
          queries:
            - kind: TimeSeriesQuery
              spec:
                plugin:
                  kind: PrometheusTimeSeriesQuery
                  spec:
                    query: up
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
```

Apply it:

```sh
kubectl apply -f persesdashboard-payments-overview.yaml
```

Then check the result:

```sh
kubectl -n payments get persesdashboard payments-overview \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards/payments-overview | jq .spec.display'
```

`Available` is `True`, and the Perses API returns the display name `Payments Overview`. To see it drawn, start `kubectl -n perses port-forward svc/perses 8080:8080` in a second terminal and open `http://perses.localtest.me:8080`; the project `payments` holds the dashboard.

## Change it, delete it

The object is the source of truth, so a change goes into the object. Change the display name with a patch and read Perses again:

```sh
kubectl -n payments patch persesdashboard payments-overview --type merge \
  -p '{"spec":{"config":{"display":{"name":"Payments Health"}}}}'
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards/payments-overview | jq -r .spec.display.name'
```

Perses now answers `Payments Health`. The operator compared the object with the Perses copy, found a difference, and updated the copy. A change made the other way, in the Perses user interface or through its API, is not watched: it stays until the operator next reconciles this object, and then the operator overwrites it with the object's content.

Deleting the object deletes the dashboard from every server it was sent to. Try it, then apply the file again to bring the dashboard back with its original name:

```sh
kubectl -n payments delete persesdashboard payments-overview
kubectl apply -f persesdashboard-payments-overview.yaml
```

Between the two commands, the Perses API answers `404` for the dashboard. The project `payments` stays, even after its last object is gone: the operator creates projects but never deletes them.

## Which servers receive a dashboard

`instanceSelector` is a standard Kubernetes label selector over `Perses` resources. The operator lists every `Perses` resource in the cluster whose **own** `metadata.labels` match, and sends the dashboard to each one that is `Available`. Without `instanceSelector`, every `Perses` resource in the cluster matches. Labels under a `Perses` resource's `spec.metadata.labels` do not count: those go onto the server's pods and Service, not onto the resource.

When nothing matches, the dashboard waits. The reason on its conditions is `PersesMissing`, and the operator retries every minute, so the dashboard arrives on its own as soon as a matching server exists. The other common reason is `ValidationFailed`: the operator found the server, sent the dashboard, and the Perses server refused it, for example because a layout refers to a panel that does not exist. The message then holds the server's own explanation. Both reasons are on the object, which is why every check of a dashboard starts with its conditions.

You can now declare a dashboard, change it and delete it through its object, and read why it did not arrive. The datasource and the dashboard together are a team's complete delivery, which is what the graded lab asks for.

## Common pitfalls

> [!WARNING]
> - **Editing the dashboard in the Perses user interface.** The next reconciliation of the object overwrites your change. Change the object.
> - **Putting the selector label on the wrong part of the `Perses` resource.** `instanceSelector` reads `metadata.labels` of the `Perses` resource, not `spec.metadata.labels`.
> - **Removing `instanceSelector` to make a dashboard sync.** Then it goes to every Perses server in the cluster, including ones that should not have it.
> - **Expecting the project to disappear.** The operator never deletes a project; remove it with `percli` or the API if you must.

## Your mission: Give Two Teams Their Own Dashboards

You can now declare a datasource and a dashboard for a team and prove both in Perses. The graded lab gives you two empty team namespaces, `payments` and `catalog`, and asks you to give each team its own Prometheus datasource and overview dashboard, delivered as custom resources and selected by the server's label.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-111-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-111-lab-020-01
astrona start ats-111-playground-020-01
```
