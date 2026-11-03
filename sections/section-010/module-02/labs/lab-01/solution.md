# Solution: Make Perses Data Survive A Restart

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the conditions of the resource, the StatefulSet and its claim, the memory limit, and that the project survives the deletion of the pod.

## Step 1: Write the resource

The storage field decides the workload. A `pvcTemplate` gives a StatefulSet and a claim. Save this as `perses-archive.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: Perses
metadata:
  name: archive
  namespace: archive
  labels:
    app.kubernetes.io/instance: archive
spec:
  image: docker.io/persesdev/perses:v0.54.0
  containerPort: 8080
  config:
    database:
      file:
        folder: /perses
        extension: yaml
  storage:
    pvcTemplate:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
  resources:
    requests:
      memory: 128Mi
    limits:
      memory: 512Mi
```

Apply it:

```sh
kubectl apply -f perses-archive.yaml
```

## Step 2: Wait for the server

The operator creates the StatefulSet a few seconds after you apply the resource:

```sh
kubectl -n archive rollout status statefulset/archive
kubectl -n archive get perses,statefulsets,deployments,pvc
```

The listing shows a StatefulSet, no Deployment, and a claim in the state `Bound`. If the rollout command says the StatefulSet does not exist yet, wait a few seconds and run it again.

## Step 3: Create the project

Send the request from the `tester` pod, which can reach the Service `archive`:

```sh
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"kind":"Project","metadata":{"name":"records"},"spec":{}}' \
  http://archive.archive:8080/api/v1/projects
```

## Step 4: Prove it survives

Delete the pod and read the project again:

```sh
kubectl -n archive delete pod archive-0
kubectl -n archive rollout status statefulset/archive
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://archive.archive:8080/api/v1/projects | jq -r ".[].metadata.name"'
```

The list contains `records`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `storage.emptyDir` | The operator creates a Deployment and the project is lost with the pod |
| A StatefulSet and a claim written by hand | The grader requires them to come from the `Perses` resource |
| A claim but no matching folder | The database is written into the pod and the project is lost anyway |

## Common mistakes

- Setting the label only on the pod and not on the resource. The server works, but a dashboard selector would not find it.
- Creating the project before the pod is ready. The request is refused and no project exists.
- Reading `Available=True` as proof of persistence. Delete the pod and read the project.
