# Status Conditions And Troubleshooting

When a Perses server does not run, the first instinct is to look at the pod. With an operator, the first place to look is one step earlier: the `Perses` resource itself, where the operator writes what it did and why it stopped. This part reads those status conditions, shows the one case where they say less than you think, and breaks the server on purpose so you see each signal once.

## Two conditions: Available and Degraded

The operator writes two status conditions on every `Perses` resource. A status condition is an entry in `.status.conditions` with a `type`, a `status` (`True`, `False` or `Unknown`), a short `reason` and a `message`. Print both conditions of your server:

<!-- astrona:playground:renew -->

```sh
kubectl -n perses get perses perses \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
```

A healthy resource shows `Available=True` with reason `Reconciled` and `Degraded=False` with the same reason. The two read together: `Degraded=True` means the operator stopped part-way, and its reason and message say where.

`Available=True` does **not** mean the Perses pod serves requests. In operator v0.5.0, the operator sets `Available=True` at the end of a reconciliation that created or updated all the objects. It does not wait for the pod to become ready. A wrong image tag still gives `Available=True`, while the pod waits forever in `ImagePullBackOff`. So a check of a server always has two halves: the conditions, and the workload itself.

```sh
kubectl -n perses get deployment perses
kubectl -n observability exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' http://perses.perses:8080/api/v1/projects
```

A ready Deployment shows `1/1`, and the request from the `tester` pod returns `200`. Those two facts, with the conditions, prove a running server.

## Break the resource: a mount without a volume

The operator validates a few things before it creates anything. One of them is that every entry in `spec.volumeMounts` names a volume in `spec.volumes`. Remove the volume `notes` but keep its mount, to see what that check does:

```sh
kubectl -n perses patch perses perses --type json -p '[{"op":"remove","path":"/spec/volumes"}]'
```

If your resource has no `notes` volume because you skipped the previous change, apply the mount on its own first with `kubectl -n perses patch perses perses --type merge -p '{"spec":{"volumeMounts":[{"name":"notes","mountPath":"/etc/perses/notes"}]}}'`. Now print the conditions again with the same `jsonpath` command as above. `Degraded` turns `True` with reason `InvalidConfiguration`, and the message names the mount path and the missing volume. The operator stopped at that check, so it did not touch the Deployment: the old pod keeps running the old configuration.

The operator log says the same thing in more words. The controller runs as the Deployment `perses-operator-controller-manager`, and its log is in the container `manager`:

```sh
kubectl -n perses-operator logs deploy/perses-operator-controller-manager -c manager --tail=30
```

Look for the line that mentions `volumeMount` and `volume`; the operator logs it at error level and retries the reconciliation with a growing delay. Put the volume back by applying your saved `perses-perses.yaml` again, and the conditions return to `Available=True` and `Degraded=False`.

## Break the image: Available, but not serving

The second kind of fault passes every check of the operator. Set an image tag that does not exist; the real tag starts with a `v`:

```sh
kubectl -n perses patch perses perses --type merge -p '{"spec":{"image":"docker.io/persesdev/perses:0.54.0"}}'
```

The conditions stay `Available=True` and `Degraded=False`, because the operator updated the Deployment without an error. The problem is one level down. Look at the new pod and its events:

```sh
kubectl -n perses get pods
kubectl -n perses get events --sort-by=.lastTimestamp | tail -5
```

The new pod is in `ErrImagePull` or `ImagePullBackOff`, and the events name the image that cannot be pulled. The old pod keeps serving until the new one is ready, so the request from `tester` may still return `200`, for the old version. Put the tag back with `docker.io/persesdev/perses:v0.54.0`, or apply `perses-perses.yaml` again.

The order of checks is now clear, from the resource down: the conditions of the `Perses` resource, the operator log when `Degraded` is `True`, the Deployment and its pods, the events of those pods, and a request to the API. Each step either finds the cause or rules out a layer. What you cannot see yet is a fault between the operator and a server that looks healthy, because nothing so far asks the operator to talk to the server.

## Common pitfalls

> [!WARNING]
> - **Trusting `Available=True` alone.** It says the operator created the objects, not that the pod is ready. Always check the Deployment and send a request.
> - **Looking at the pod first.** When `Degraded` is `True`, the operator stopped before it changed the pod, so the pod shows the old, healthy state.
> - **Reading the wrong container's log.** The operator pod also runs `kube-rbac-proxy`; the reconciliation log is in the container `manager`.
> - **Deleting the resource to start again.** That deletes the server and its data on `emptyDir`. Fix the field in place.

## Your mission: Fix A Perses Server That Never Serves

You can now read a `Perses` resource's conditions, the operator log and the pod events, and tell a configuration the operator refuses from a server that never starts. The graded lab gives you a `Perses` resource with more than one fault and asks you to make the server serve without deleting the resource and without dropping the extra volume it mounts.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-111-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-111-lab-010-01
astrona start ats-111-playground-010-01
```
