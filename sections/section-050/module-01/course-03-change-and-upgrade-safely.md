# Change And Upgrade Safely

A change to a Perses server can be a new memory limit, a new image or a changed configuration, and each one restarts the pod. A change to the operator can replace the definitions of the custom resources that every team uses. This part shows how a change rolls out, how to undo it, and the order to follow when a new version is involved.

## A change goes through the Perses resource

The operator owns the Deployment of a server. A change made directly to the Deployment is overwritten by the next reconcile. Change the `Perses` resource instead. Raise the memory limit of the playground server and watch the rollout:

<!-- astrona:playground:renew -->

```sh
kubectl -n perses patch perses perses --type merge \
  -p '{"spec":{"resources":{"limits":{"memory":"640Mi"}}}}'
kubectl -n perses rollout status deployment/perses
kubectl -n perses get deployment perses \
  -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}{"\n"}'
```

The Deployment now has `640Mi`, and the old pod was replaced. On a server with `emptyDir` the data of the old pod is gone, which is the reason the previous part comes first. On a server with a volume, the new pod mounts the same volume.

## Undo a change

To undo, apply the old value to the `Perses` resource:

```sh
kubectl -n perses patch perses perses --type merge \
  -p '{"spec":{"resources":{"limits":{"memory":"512Mi"}}}}'
kubectl -n perses rollout status deployment/perses
```

`kubectl rollout undo` on the Deployment looks like a faster way, and it is not one. The operator reconciles the Deployment from the `Perses` resource, so it can put the value of the resource back over your undo. A rollback is a change to the object that is the source.

If the change was delivered from Git, revert the commit instead and let the delivery apply it. The pipeline and the cluster then agree.

## Watch a bad change fail

Set an image tag that does not exist and watch what happens to a running server:

```sh
kubectl -n perses patch perses perses --type merge \
  -p '{"spec":{"image":"docker.io/persesdev/perses:v0.0.0-not-a-tag"}}'
sleep 20
kubectl -n perses get pods
kubectl -n perses get events --sort-by=.lastTimestamp | tail -5
```

The new pod cannot pull the image and shows `ErrImagePull` or `ImagePullBackOff`. A Deployment rolling update keeps the old pod running until the new one is ready, so the server keeps answering. Check this by calling the API, then restore the image:

```sh
kubectl -n observability exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' http://perses.perses:8080/api/v1/projects
kubectl -n perses patch perses perses --type merge \
  -p '{"spec":{"image":"docker.io/persesdev/perses:v0.54.0"}}'
kubectl -n perses rollout status deployment/perses
```

The status is `200` during the failure. A server on a StatefulSet with one replica behaves differently, because there is no second pod to keep serving, so test the behaviour of your own setup.

## Upgrade in the right order

The operator, its custom resource definitions and the Perses image are three things that move together:

1. Back up the data that only the server has.
2. Read the release notes of the new versions for changes to fields and to the server configuration.
3. Upgrade the custom resource definitions first, because Helm does not upgrade the definitions that a chart ships in its `crds` folder. Apply the new definitions with `kubectl apply --server-side`, from the chart version that you are upgrading to.
4. Upgrade the operator with `helm upgrade`, with the same values as before.
5. Change `spec.image` of one non-production server, wait for `Available`, and check a dashboard.
6. Change the production servers.

The earlier module on the operator install shows the definitions step. Skipping it is the reason an upgraded operator reports fields the definitions do not know.

## Test on a second server

A server that selects a label like `env=staging` gives you a place to try the new image with the same objects. Point a dashboard selector at it, as in the earlier module on routing. If the new version refuses a dashboard, the condition on the object says so before production sees anything.

## Common pitfalls

> [!WARNING]
> - **Editing the Deployment of a server.** The operator reconciles it back.
> - **Using `kubectl rollout undo` on an operator-managed Deployment.** Change the `Perses` resource.
> - **Upgrading the operator without upgrading the definitions.** New fields are rejected.
> - **Using `latest` or a moving image tag.** Pin a version so a restart does not upgrade the server.
