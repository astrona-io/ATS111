# Solution: Deliver An Ordered, Parameterised Ops Pipeline

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks five things: that the source and both deliveries are ready, the dependency, the substitution source and the health check, the datasource address in Perses, and the served dashboard.

## Step 1: Write the two deliveries

Save this as `flux-ops.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: ops-datasources
  namespace: flux-system
spec:
  interval: 5m
  timeout: 3m
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./ops/datasources
  prune: true
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: platform-vars
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: perses
      namespace: perses
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: ops-dashboards
  namespace: flux-system
spec:
  interval: 5m
  dependsOn:
    - name: ops-datasources
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./ops/dashboards
  prune: true
```

Apply it:

```sh
kubectl apply -f flux-ops.yaml
```

## Step 2: Run the deliveries

```sh
flux reconcile kustomization ops-datasources --with-source
flux reconcile kustomization ops-dashboards
flux get kustomizations
```

Both become `Ready`. If the second says that its dependency is not ready, wait for the first and run the command again.

## Step 3: Check Perses

```sh
kubectl -n payments get persesdatasource ops-prometheus -o jsonpath='{.spec.config.plugin.spec.proxy.spec.url}{"\n"}'
kubectl -n observability exec deploy/tester -- sh -c \
  "curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards | jq -r '.[].metadata.name'"
```

The first prints the address from the ConfigMap. The second lists `payments-ops`.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Applying the files in `ops/` with `kubectl` | The grader requires Flux to own the objects |
| Writing the address into the file in Git | The task keeps the address in the ConfigMap |
| No `postBuild` | The datasource keeps the text `${PROMETHEUS_URL}` and Perses refuses it |
| No `dependsOn` | The deliveries run without an order and the check on the dependency fails |

## Common mistakes

- Putting `postBuild` on `ops-dashboards` instead of `ops-datasources`. The variable is in the datasource file.
- Reading `Ready` on Flux as proof. Read the address in Perses.
- Misspelling the ConfigMap name. The delivery then fails with a message that names it.
