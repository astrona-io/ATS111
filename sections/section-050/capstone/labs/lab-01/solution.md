# Solution: Recover A Broken Perses Platform

Work the task yourself first. Running `astrona submit -c sections/section-050/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: The server does not run

Follow the order: conditions, events, then the pod.

```sh
kubectl -n reports get perses reports -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
kubectl -n reports get pods
kubectl -n reports get events --sort-by=.lastTimestamp | tail -5
```

The pod cannot pull `docker.io/persesdev/perses:v0.54.0-typo`. Correct the image:

```sh
kubectl -n reports patch perses reports --type merge \
  -p '{"spec":{"image":"docker.io/persesdev/perses:v0.54.0"}}'
kubectl -n reports rollout status deployment/reports
```

## Step 2: weekly never arrives

Compare the selector with the labels of the servers:

```sh
kubectl get perses -A --show-labels
kubectl -n finance get persesdashboard weekly -o jsonpath='{.spec.instanceSelector}{"\n"}'
```

The selector says `reportz`. Correct it:

```sh
kubectl -n finance patch persesdashboard weekly --type merge \
  -p '{"spec":{"instanceSelector":{"matchLabels":{"app.kubernetes.io/instance":"reports"}}}}'
```

## Step 3: monthly is refused

Once the server runs, read the conditions of `monthly`. The layout refers to the panel `totals`, which does not exist. Add the panel:

```sh
kubectl -n finance patch persesdashboard monthly --type merge -p '{"spec":{"config":{"panels":{"totals":{"kind":"Panel","spec":{"display":{"name":"Totals"},"plugin":{"kind":"Markdown","spec":{"text":"Monthly totals"}}}}}}}}'
```

## Step 4: Check and submit

```sh
kubectl -n finance get persesdashboards
kubectl -n observability exec deploy/tester -- sh -c \
  "curl -s http://reports.reports:8080/api/v1/projects/finance/dashboards | jq -r '.[].metadata.name'"
astrona submit -c sections/section-050/capstone/labs/lab-01
```

Both dashboards are `Available` and listed.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Deleting the server and creating a new one | The task forbids it, and the data of the old server is lost |
| Removing the layout from `monthly` | The task keeps the reference |
| Setting the selector of `weekly` to `perses` | The dashboard then lands on the wrong server |

## Common mistakes

- Reading the operator log first. The events of the namespace name the image at once.
- Fixing `monthly` before the server runs. The refusal cannot show until a server answers.
- Merge-patching `layouts` and replacing the whole list.
