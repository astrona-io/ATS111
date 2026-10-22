# Solution: Fix Dashboards That Never Reach Perses

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the label on the `Perses` resource itself, the four objects `Available` and in Perses, a query through each datasource, and the selectors still in place.

## Step 1: Read every condition

Print the `Available` reason and message of all four objects:

```sh
for team in payments catalog; do
  kubectl -n "$team" get persesdatasource,persesdashboard \
    -o jsonpath='{range .items[*]}{.kind}/{.metadata.name}: {.status.conditions[?(@.type=="Degraded")].reason} {.status.conditions[?(@.type=="Degraded")].message}{"\n"}{end}'
done
```

All four show the reason `PersesMissing` and the message that no Perses instances match the label selector. The operator found no `Perses` resource with the label the objects select.

## Step 2: Find where the label went

```sh
kubectl -n perses get perses perses -o jsonpath='{.metadata.labels}{"\n"}{.spec.metadata.labels}{"\n"}'
```

The resource's own `metadata.labels` holds only `team: platform`. The label `app.kubernetes.io/instance: perses` is under `spec.metadata.labels`, which the operator puts on the pods and the Service, not on the resource. `instanceSelector` reads the resource's own labels, so nothing matches. Add the label to the resource:

```sh
kubectl -n perses label perses perses app.kubernetes.io/instance=perses
```

The operator retries `PersesMissing` every minute, so within a minute the payments objects and the catalog datasource turn `Available`. Run the command from step 1 again after a minute.

## Step 3: Read the catalog dashboard's new reason

The catalog dashboard now shows the reason `ValidationFailed`. The message holds the Perses server's answer: a layout refers to a panel that does not exist. Look at the reference:

```sh
kubectl -n catalog get persesdashboard catalog-overview \
  -o jsonpath='{.spec.config.layouts[0].spec.items[0].content}{"\n"}{.spec.config.panels}{"\n"}' | cut -c1-200
```

The layout points at `#/spec/panels/up-missing`, but the only panel is `up`. Point the layout at the panel that exists:

```sh
kubectl -n catalog patch persesdashboard catalog-overview --type json \
  -p '[{"op":"replace","path":"/spec/config/layouts/0/spec/items/0/content/$ref","value":"#/spec/panels/up"}]'
```

## Step 4: Find why the catalog datasource returns no data

The catalog datasource is `Available`, so its copy reached Perses. Query through it and compare its URL with the payments one:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  "curl -s 'http://perses.perses:8080/proxy/projects/catalog/datasources/prometheus/api/v1/query?query=up' | jq -r .status"
kubectl -n catalog get persesdatasource prometheus -o jsonpath='{.spec.config.plugin.spec.proxy.spec.url}{"\n"}'
```

The query does not return `success`, and the URL names the namespace `monitoring`. Prometheus runs in `observability`. Fix the URL:

```sh
kubectl -n catalog patch persesdatasource prometheus --type merge \
  -p '{"spec":{"config":{"plugin":{"spec":{"proxy":{"spec":{"url":"http://prometheus.observability.svc.cluster.local:9090"}}}}}}}'
```

## Step 5: Prove everything

```sh
for team in payments catalog; do
  kubectl -n "$team" get persesdatasource,persesdashboard \
    -o jsonpath='{range .items[*]}{.kind}/{.metadata.name}: {.status.conditions[?(@.type=="Available")].status}{"\n"}{end}'
  kubectl -n observability exec deploy/tester -- sh -c \
    "curl -s 'http://perses.perses:8080/proxy/projects/$team/datasources/prometheus/api/v1/query?query=up' | jq -r .status"
done
```

All four objects print `True`, and both queries print `success`. If an object still shows an old reason, change an annotation on it to start a new reconciliation, for example `kubectl -n catalog annotate persesdashboard catalog-overview astrona.io/retry-at="$(date +%s)" --overwrite`.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove `instanceSelector` from the objects | They sync to every Perses server in the cluster; the grader requires the selectors |
| Delete and recreate the `Perses` resource with the label | The server's data on `emptyDir` is lost, and the grader checks that the original object was fixed |
| Add a panel named `up-missing` | The dashboard is accepted, but it holds an empty duplicate panel instead of a correct reference |

## Common mistakes

- Labelling the pods or the Service. `instanceSelector` reads the `Perses` resource, not the objects the operator created.
- Taking `Available=True` on the catalog datasource as proof it works. Query through it.
