# Solution: Fix A Perses Server That Never Serves

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the resource's conditions, a ready server on the right image that answers its API, the volume `extra` from the ConfigMap `perses-extra`, and that the `Perses` resource is the original object.

## Step 1: Read the conditions

Start at the resource, not at the pods:

```sh
kubectl -n perses get perses perses \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
```

`Degraded` is `True` with reason `InvalidConfiguration`. The message says that the volume mount at `/etc/perses/extra` references the volume `extra`, which is not defined in `spec.volumes`. The operator stopped at this check, so `kubectl -n perses get deployments` shows no Deployment `perses` yet.

## Step 2: Confirm it in the operator log

The operator log gives the same cause with more detail:

```sh
kubectl -n perses-operator logs deploy/perses-operator-controller-manager -c manager --tail=30
```

The error line names the volume mount and the missing volume. The operator retries the reconciliation with a growing delay, so the line repeats.

## Step 3: Define the volume and correct the image

Look at the resource once more before you change it:

```sh
kubectl -n perses get perses perses -o jsonpath='{.spec.image}{"\n"}{.spec.volumeMounts}{"\n"}'
```

The image is `docker.io/persesdev/perses:0.54.0`. Perses tags start with a `v`, so that tag does not exist; the operator cannot see that, and the pod would fail with `ImagePullBackOff` as soon as the volume problem is fixed. Fix both faults in one change. The ConfigMap `perses-extra` already exists in the namespace:

```sh
kubectl -n perses patch perses perses --type merge -p '{
  "spec": {
    "image": "docker.io/persesdev/perses:v0.54.0",
    "volumes": [{"name": "extra", "configMap": {"name": "perses-extra"}}]
  }
}'
```

A merge patch replaces `spec.volumes` as a whole list and leaves `spec.volumeMounts` as it is, so the mount stays.

## Step 4: Prove the server serves

Wait for the operator to create the Deployment and for the pod to become ready:

```sh
kubectl -n perses rollout status deployment/perses
kubectl -n perses get perses perses \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
kubectl -n observability exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' http://perses.perses:8080/api/v1/projects
```

The rollout finishes, `Available` is `True` and `Degraded` is `False`, and the request returns `200`. If the rollout command says the Deployment does not exist, wait a few seconds: the operator retries with a delay after the earlier errors.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the volume mount | The server starts, but without the team's files, and the grader requires the mount |
| Delete the `Perses` resource and apply a new one | The server's data on `emptyDir` is lost, and the grader checks that the original object was fixed |
| Edit the Deployment's image by hand | The operator puts its own value back on the next reconciliation |
| Fix only the volume | The operator is happy, `Available` turns `True`, and the pod never pulls its image |

## Common mistakes

- Reading the pod first. While `Degraded` is `True`, there is no pod to read.
- Trusting `Available=True` after the volume fix. Check the Deployment's ready replicas and send a request.
- Setting `volumes` with a JSON patch `add` on a path that does not exist yet; a merge patch is simpler here.
