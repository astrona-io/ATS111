# Solution: Make The Operator Reach Its Perses Server

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the Service `perses` reaches a ready pod, the server has enough memory and is not crash-looping, the `payments` resources are `Available` and in Perses, and the `Perses` resource is the original object.

## Step 1: Read the dashboard's conditions

The symptom is in `payments`, so start there:

```sh
kubectl -n payments get persesdashboard payments-overview \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
```

`Degraded` is `True` with reason `PersesConnectionFailed`. The operator found a `Perses` server that matches the dashboard's `instanceSelector`, but it could not connect to it. The `PersesDatasource` `prometheus` shows the same reason.

## Step 2: Compare the operator's address with the Services

The operator reaches a server at `http://<Perses name>.<namespace>.svc.cluster.local:<containerPort>`, here `http://perses.perses.svc.cluster.local:8080`. Look at what exists:

```sh
kubectl -n perses get services
kubectl -n perses get perses perses -o jsonpath='{.spec.service}{"\n"}{.spec.resources}{"\n"}'
```

There is a Service `perses-ui` and no Service `perses`. `spec.service.name` renamed the Service, but the operator still uses the name of the resource. That is the first fault. The second output line also shows the memory: a request and a limit of `16Mi`.

## Step 3: Read why the pod restarts

```sh
kubectl -n perses get pods
kubectl -n perses describe pod -l app.kubernetes.io/instance=perses | grep -A3 'Last State'
```

The pod restarts again and again, and its last state shows the reason `OOMKilled`: the container used more than its `16Mi` limit and the kernel killed it. That is the second fault.

## Step 4: Fix both faults in the resource

Remove the Service override and set realistic memory in one JSON patch:

```sh
kubectl -n perses patch perses perses --type json -p '[
  {"op": "remove", "path": "/spec/service"},
  {"op": "replace", "path": "/spec/resources", "value": {"requests": {"memory": "128Mi"}, "limits": {"memory": "512Mi"}}}
]'
kubectl -n perses rollout status deployment/perses
kubectl -n perses get services
```

The operator creates the Service `perses`, and the new pod becomes ready. The old Service `perses-ui` stays behind; it does no harm, and you may delete it.

## Step 5: Make the payments resources sync now

The operator retried the failed dashboard and datasource with a growing delay, so they may take minutes to sync on their own. Any change to a custom resource starts a new reconciliation at once, so change an annotation on both:

```sh
kubectl -n payments annotate persesdashboards,persesdatasources --all \
  "astrona.io/retry-at=$(date +%s)" --overwrite
kubectl -n payments get persesdashboard payments-overview \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
```

`Available` is now `True`. Prove it from the server's side:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards/payments-overview
```

The JSON answer holds the dashboard with `"name":"Payments Overview"` under `spec.display`. The operator also created the project `payments`, named after the namespace.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Rename the `Perses` resource to `perses-ui` | You cannot rename an object; deleting and recreating it loses the data and breaks `http://perses.perses:8080` for other teams |
| Create a Service `perses` by hand | It works until the operator's view and yours drift apart; the resource still declares the wrong Service name |
| Remove only the memory limit | The pod stops crashing, but nothing fixes the address the operator uses |
| Create the dashboard with `percli apply` | The grader expects the custom resource to be `Available`; the next reconciliation also overwrites it |

## Common mistakes

- Reading only the `Perses` resource. It says `Available=True`, because it does not wait for the pod or test the connection.
- Waiting for the dashboard to sync on its own after the fix. The retry delay can be long; change an annotation to start a reconciliation now.
