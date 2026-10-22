# The Perses Resource

A `Perses` resource is the only object you write to run a Perses server. Every other object of the server comes from it, so a wrong field here shows up as a wrong Deployment, a wrong Service or a server the operator cannot reach. This part reads the resource in your playground field by field, changes it, and follows the change into the objects the operator manages.

## Read the resource that runs your server

The playground applied one `Perses` resource named `perses` in the namespace `perses`. Read it back as the API server stores it:

<!-- astrona:playground:renew -->

```sh
kubectl -n perses get perses perses -o yaml
```

The output has three parts. `metadata.labels` holds `app.kubernetes.io/instance: perses`; dashboards and datasources use that label later to find this server. `spec` holds what you declared, and `status.conditions` holds what the operator reported back. The fields under `spec` that matter most are these:

| Field | What it sets |
| --- | --- |
| `image` | The Perses server image; here `docker.io/persesdev/perses:v0.54.0`. Without it the operator uses its own default, which is the same tag in operator v0.5.0 |
| `containerPort` | The port the server listens on; `8080` when you leave it out |
| `config` | The complete Perses server configuration, the same keys as the server's configuration file |
| `config.database.file` | A file database: a folder in the pod and the file extension (`yaml` or `json`) |
| `storage` | Where that folder lives: `emptyDir` (lost on restart) or `pvcTemplate` (a PersistentVolumeClaim) |
| `service` | Optional name and annotations for the Service |
| `resources`, `volumes`, `volumeMounts`, `replicas`, `logLevel` | The usual pod settings, passed to the workload |

The `config` block is not a summary. The operator writes it into a ConfigMap and mounts it as the server's configuration file, so any key the Perses configuration accepts can go there.

## The objects the operator built from it

The operator chose a workload kind and names from this resource. Look at what it created in the namespace:

```sh
kubectl -n perses get deployments,statefulsets,services,configmaps -l app.kubernetes.io/managed-by=perses-operator
```

You see a Deployment named `perses`, a Service named `perses` on port `8080`, and a ConfigMap with the configuration. There is no StatefulSet. The rule comes from the operator's code: with a file database, `storage.emptyDir` gives a Deployment, and any other storage gives a StatefulSet with a PersistentVolumeClaim, because a file database on a real disk must stay with one pod. Every object carries the label `app.kubernetes.io/managed-by=perses-operator`, which is how the selector above found them.

The Service name matters more than it looks. The operator itself talks to the Perses server through the REST API, to create projects, dashboards and datasources. It builds that address from the **name of the `Perses` resource**, not from the Service: `http://<name>.<namespace>.svc.cluster.local:<containerPort>`, here `http://perses.perses.svc.cluster.local:8080`. If you set `spec.service.name` to anything else, the Service gets that name, the address the operator uses no longer exists, and every dashboard and datasource fails to sync.

## Reach the server yourself

The Perses server answers inside the cluster at `http://perses.perses:8080`. From your machine, start a port-forward in a second terminal and leave it running:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

Then ask the server for its projects with `percli`, the Perses command-line tool. Authentication is off on this server, so `percli login` only records the address:

```sh
percli login http://perses.localtest.me:8080
percli get project
```

The list is empty or short: this server holds no dashboards yet. The name `perses.localtest.me` resolves to `127.0.0.1` on your machine, so the request goes through the port-forward. If the name does not resolve, add `127.0.0.1 perses.localtest.me` to `/etc/hosts`.

## Change the resource and watch the operator follow

Now change the server through the resource. The change below raises the log level and mounts an extra ConfigMap into the pod, the two kinds of change you make most often. First create the ConfigMap the volume needs:

```sh
kubectl -n perses create configmap perses-notes --from-literal=README.txt="Notes for the Perses server."
```

Save this as `perses-perses.yaml`:

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
  logLevel: debug
  config:
    database:
      file:
        folder: /perses
        extension: yaml
  storage:
    emptyDir: {}
  resources:
    requests:
      memory: 128Mi
    limits:
      memory: 512Mi
  volumes:
    - name: notes
      configMap:
        name: perses-notes
  volumeMounts:
    - name: notes
      mountPath: /etc/perses/notes
      readOnly: true
```

Apply it:

```sh
kubectl apply -f perses-perses.yaml
```

Then check the result:

```sh
kubectl -n perses rollout status deployment/perses
kubectl -n perses get deployment perses -o jsonpath='{.spec.template.spec.volumes[*].name}{"\n"}'
```

The operator saw the changed resource, updated the Deployment, and Kubernetes rolled out a new pod. The volume list of the Deployment now includes `notes`. Because the database is on an `emptyDir`, the new pod starts with an empty database; that is fine for a playground and wrong for anything you want to keep.

You now know the fields of a `Perses` resource, the objects the operator builds from it, and the address the operator uses to reach the server. The open question is how to tell, from the resource alone, whether all of that actually worked.

## Common pitfalls

> [!WARNING]
> - **Renaming the Service with `spec.service.name`.** The operator still connects to `http://<Perses name>.<namespace>.svc.cluster.local`, so dashboards and datasources stop syncing.
> - **Expecting data to survive a restart on `emptyDir`.** The file database lives in the pod. Use `storage.pvcTemplate` (a StatefulSet) or an SQL database for anything real.
> - **Editing the Deployment instead of the resource.** The operator replaces hand edits on its next reconciliation.
> - **Forgetting the label on the resource itself.** Dashboards and datasources select servers by the labels in `metadata.labels`, not the ones under `spec.metadata.labels`.
