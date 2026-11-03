# A Troubleshooting Playbook

Problems on a Perses platform fall into three kinds: the server does not run, the server refuses an object, or the object never reaches the server. Each kind has a different first place to look. This part breaks the playground three ways and fixes each by following the same order.

## The order

Always look in this order, and stop at the first error:

1. The conditions of the object that does not work.
2. The events and the log of the pod it depends on.
3. The log of the operator.

The order follows the path of a request: the object, the server, the operator that connects them. The first place that shows an error is closest to the cause.

## Problem one: the server does not run

Break the image of the server in a new `Perses` resource. Save this as `perses-broken.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: reports
---
apiVersion: perses.dev/v1alpha2
kind: Perses
metadata:
  name: reports
  namespace: reports
  labels:
    app.kubernetes.io/instance: reports
spec:
  image: docker.io/persesdev/perses:v0.54.0-typo
  containerPort: 8080
  config:
    database:
      file:
        folder: /perses
        extension: yaml
  storage:
    emptyDir: {}
```

Apply it:

```sh
kubectl apply -f perses-broken.yaml
```

Then follow the order:

```sh
kubectl -n reports get perses reports \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
kubectl -n reports get pods
kubectl -n reports get events --sort-by=.lastTimestamp | tail -5
```

The resource is not `Available`, the pod is in `ImagePullBackOff` or `ErrImagePull`, and the events name the image that cannot be pulled. The cause is in the event. Fix the tag in the file, apply it, and wait for the rollout:

```sh
kubectl -n reports patch perses reports --type merge \
  -p '{"spec":{"image":"docker.io/persesdev/perses:v0.54.0"}}'
kubectl -n reports rollout status deployment/reports
```

## Problem two: the server refuses an object

Send a dashboard with a reference to a missing panel to the new server. Save this as `dashboard-refused.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: refused
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: reports
  config:
    display:
      name: Refused
    duration: 1h
    panels: {}
    layouts:
      - kind: Grid
        spec:
          items:
            - x: 0
              y: 0
              width: 12
              height: 6
              content:
                $ref: "#/spec/panels/gone"
```

Apply it and follow the order:

```sh
kubectl apply -f dashboard-refused.yaml
kubectl -n payments get persesdashboard refused \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
```

The first place already shows the error: the condition names the refusal and the message holds the server's text. The server log would show the same request. Fix the reference by replacing the layout with an empty list, and apply the file again.

## Problem three: the object never arrives

Change the selector of the dashboard to a label no server has:

```sh
kubectl -n payments patch persesdashboard refused --type merge \
  -p '{"spec":{"instanceSelector":{"matchLabels":{"app.kubernetes.io/instance":"reportz"}}}}'
kubectl -n payments get persesdashboard refused \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://reports.reports:8080/api/v1/projects/payments/dashboards | jq -r ".[].metadata.name"'
```

The object may show no error at all, and the server has no dashboard with that name. A selector that matches no server is not a failure of any component, which makes this problem the hardest to see. Check the selector against the labels of the servers:

```sh
kubectl get perses -A --show-labels
```

The labels list `app.kubernetes.io/instance=reports` and `app.kubernetes.io/instance=perses`. The selector says `reportz`. Correct it and the dashboard arrives. If the labels and the selector agree and nothing arrives, read the operator log for the object name.

## Clean up

```sh
kubectl delete -f dashboard-refused.yaml
kubectl delete -f perses-broken.yaml
```

## Common pitfalls

> [!WARNING]
> - **Starting with the operator log.** The conditions of the object are shorter and closer to the cause.
> - **Treating "no error" as "working".** A selector that matches nothing reports nothing.
> - **Fixing a delivered object in the cluster.** The next sync restores the bad version. Fix it in the source.
> - **Deleting the server to fix it.** On `emptyDir` the data is lost, and the cause stays.
