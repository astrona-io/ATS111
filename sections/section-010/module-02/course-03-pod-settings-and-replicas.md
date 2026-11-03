# Pod Settings And Replicas

The `Perses` resource is a thin layer over a pod specification. Most of its fields are the pod fields you already know, passed to the workload the operator creates. This part shows how to find every field of the resource without a manual, sets the ones that matter for a production server, and explains why a second replica does not make a file database highly available.

## Find a field with kubectl explain

The custom resource definition (CRD) of `Perses` carries the schema of every field, and `kubectl explain` prints it from the cluster you are connected to. That makes it the reference that always matches the installed operator version. Start at the top of the spec:

<!-- astrona:playground:renew -->

```sh
kubectl explain perses.spec --api-version=perses.dev/v1alpha2
```

The output lists each field with its type and a short description. Go one level down into any object field by adding its name, for example the Service settings and the storage settings:

```sh
kubectl explain perses.spec.service --api-version=perses.dev/v1alpha2
kubectl explain perses.spec.storage --api-version=perses.dev/v1alpha2
```

Use `--recursive` to print a whole tree in one screen when you only need the field names:

```sh
kubectl explain perses.spec --api-version=perses.dev/v1alpha2 --recursive
```

This habit matters for the exam and for work. A field name you remember from one operator version may differ in another, and the cluster is the only source that is always right.

## Resources, labels and scheduling

Resource requests and limits go under `spec.resources`, exactly as in a container. The requests are what the scheduler reserves on a node. The limits are what the container may use: a container that goes over its memory limit is killed by the kernel, and the pod restarts with the reason `OOMKilled`. A server with a memory limit that is too small restarts in a loop, and the `Perses` resource still says `Available`.

Extra labels and annotations for the pods and the Service belong under `spec.metadata`. They do not label the `Perses` resource itself, and the dashboards and datasources that select this server read the resource's own `metadata.labels`. Node placement uses the same fields as a pod: `nodeSelector`, `tolerations` and `affinity`. Check the exact names with `kubectl explain` before you write them.

Apply a change to the resources and watch the Deployment follow. Save this as `perses-resources.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: Perses
metadata:
  name: perses
  namespace: perses
  labels:
    app.kubernetes.io/instance: perses
spec:
  image: docker.io/persesdev/perses:v0.54.0
  containerPort: 8080
  config:
    database:
      file:
        folder: /perses
        extension: yaml
  storage:
    emptyDir: {}
  resources:
    requests:
      cpu: 100m
      memory: 192Mi
    limits:
      memory: 512Mi
  metadata:
    labels:
      team: platform
```

Apply it:

```sh
kubectl apply -f perses-resources.yaml
```

Then check the result:

```sh
kubectl -n perses rollout status deployment/perses
kubectl -n perses get pods --show-labels
kubectl -n perses get deployment perses -o jsonpath='{.spec.template.spec.containers[0].resources}{"\n"}'
```

The new pod carries the label `team=platform`, and the Deployment shows the requests and the limit. The `Perses` resource itself does not have the label `team`: the field `spec.metadata.labels` went to the pod.

## Probes and the time a server needs to start

A liveness probe tells Kubernetes when to restart a container, and a readiness probe tells it when to send traffic to the pod. The operator sets probes for the server, and the resource exposes fields to change them. A server that loads a large database or many plugin schemas can need longer than the default before it answers, and then a probe that is too strict restarts it before it is ready. Find the probe fields with `kubectl explain perses.spec --recursive`, and change only the delay or the timeout, not the path, unless you know the server serves the new path.

## Why more replicas do not mean high availability

`spec.replicas` sets the number of pods. With a file database, each pod has its own copy of the database folder. With `emptyDir` the copies start empty and diverge. With a PersistentVolumeClaim from `pvcTemplate`, each pod of the StatefulSet gets its own claim, and the data is still not shared.

Check it on your playground server. Set two replicas, create a project through the Service, and ask for the projects several times:

```sh
kubectl -n perses patch perses perses --type merge -p '{"spec":{"replicas":2}}'
kubectl -n perses rollout status deployment/perses
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s -X POST -H "Content-Type: application/json" -d "{\"kind\":\"Project\",\"metadata\":{\"name\":\"once\"},\"spec\":{}}" http://perses.perses:8080/api/v1/projects'
kubectl -n observability exec deploy/tester -- sh -c \
  'for i in 1 2 3 4 5 6; do curl -s http://perses.perses:8080/api/v1/projects | jq -r "[.[].metadata.name] | join(\",\")"; done'
```

The Service sends each request to one of the two pods. The project `once` exists on only one of them, so some answers contain it and some do not. Scale back to one replica when you have seen it:

```sh
kubectl -n perses patch perses perses --type merge -p '{"spec":{"replicas":1}}'
```

The fix is a shared database. The `sql` database in the configuration stores resources in a MySQL-compatible server that every replica uses, and then the replicas hold the same data. The operator can run the Perses pods, but it does not run the database for you.

You can now find any field of the resource, set resources and labels, and explain why replicas need a shared database. The open question is how the connection to the server is protected.

## Common pitfalls

> [!WARNING]
> - **Scaling a file database to two replicas.** Each pod keeps its own data. The Service answers differently from request to request.
> - **A memory limit that is too small.** The container is killed with `OOMKilled` and restarts, while the resource stays `Available`.
> - **Putting scheduling labels on `spec.metadata`.** Those labels go on the pods. Selectors for dashboards read the labels of the resource.
> - **Copying a field name from memory.** Check it with `kubectl explain` on the installed version.
