# See What The Platform Is Doing

Before you change anything, find out what state the platform is in. Perses and its operator report in three ways: conditions on the custom resources, events in the namespaces, and logs from the pods. This part reads each of them on a healthy system, so the first time you meet them is not during an incident.

## Conditions on the objects

The operator writes conditions to the status of each object it manages. They are the first thing to read, because they are the operator's own summary. List the Perses server and its conditions:

<!-- astrona:playground:renew -->

```sh
kubectl -n perses get perses
kubectl -n perses get perses perses \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
```

On a healthy server `Available` is `True` and `Degraded` is `False`. Dashboards and datasources have conditions of their own, and a failure there names the reason. Make a dashboard that the server will refuse, so you see the shape of a failure. Save this as `dashboard-bad.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: broken
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Broken
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
                $ref: "#/spec/panels/missing"
```

Apply it and read its conditions after a short time:

```sh
kubectl apply -f dashboard-bad.yaml
kubectl -n payments get persesdashboard broken \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
```

The reason names the failure, and the message holds what the server said. Delete the object when you have read it: `kubectl -n payments delete persesdashboard broken`.

## Events

Events record what the controllers and the kubelet did and whether it worked. They are kept for a short time, so read them soon after a change:

```sh
kubectl -n perses get events --sort-by=.lastTimestamp
kubectl -n payments get events --sort-by=.lastTimestamp
```

The events of the `perses` namespace show the Deployment rollout and the pod start. A failed image pull, a failed probe or an out-of-memory kill appears here before it appears anywhere else.

## Logs

Two logs matter. The server log shows requests, validation errors and start-up problems:

```sh
kubectl -n perses logs deploy/perses --tail=30
```

The operator log shows each reconcile, each call it made to a server and each error it got back. Find the operator Deployment first, then read it:

```sh
kubectl -n perses-operator get deployments
kubectl -n perses-operator logs deploy/<name-from-the-listing> --tail=50
```

Read the operator log with an object name in mind. A message that names the object and the server it tried to reach tells you whether the operator found the server and what the server answered.

## Metrics

The Perses server can expose metrics for Prometheus. Ask the server for them and count what it reports:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/metrics | head -20'
```

If the server exposes the endpoint, the output is in the Prometheus text format, with the HTTP request counts and the Go runtime metrics. If it does not, the answer is an error or an empty page, and the version of the server decides it. To collect the metrics, add a scrape job to Prometheus for the Service `perses` in the namespace `perses`, port 8080. Alert on the pod restart count and on the age of the last successful reconcile where your tooling provides it.

## What to check first

| Symptom | First place to look |
| --- | --- |
| A dashboard is not in Perses | The conditions of the `PersesDashboard` |
| The server does not start | Events of the `perses` namespace, then the pod log |
| Many objects fail at once | The operator log and the conditions of the `Perses` resource |
| Only one team is affected | The conditions of that team's objects and their selectors |

## Common pitfalls

> [!WARNING]
> - **Reading only `kubectl get`.** The listing hides the reason. Read the conditions.
> - **Reading events late.** They are removed after a short time.
> - **Reading the server log for an operator problem.** If the operator never reached the server, the server log shows nothing.
> - **Assuming `/metrics` exists.** Ask the server of your version before you build an alert on it.
