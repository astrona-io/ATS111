# Provisioning Without The Operator

Not every Perses server runs under the operator. Many are installed with the Perses Helm chart as a plain Deployment, and some teams want a few fixed dashboards that nobody can delete. For both cases Perses has its own way to load resources: provisioning. This part loads a project and a dashboard from files into your server, and compares that with the custom resources you used so far.

## What provisioning does

Provisioning is a feature of the Perses server itself. In its configuration you list one or more folders under `provisioning.folders`. When the server starts, it reads every resource file in those folders and their sub-folders and writes the resources into its database. It repeats that at a fixed interval, so a provisioned resource that someone deleted comes back. The files hold Perses resources in the same format as the Perses API: `kind`, `metadata` and `spec`.

With the operator, the configuration is `spec.config` of the `Perses` resource, and the files can come from a ConfigMap mounted as an extra volume. One rule from the operator applies: an extra volume may not be mounted under `/etc/perses/provisioning`, because the operator reserves that path for its own provisioning Secrets. So the folder in this example is `/etc/perses/provisioned`.

## Load a project and a dashboard from files

A provisioned dashboard needs its project, so provision both. The two files below are plain Perses resources, not custom resources.

<!-- astrona:playground:renew -->

Save this as `project-platform.yaml`:

```yaml
kind: Project
metadata:
  name: platform
spec:
  display:
    name: Platform
```

Save this as `dashboard-platform-prometheus.yaml`:

```yaml
kind: Dashboard
metadata:
  name: prometheus-self
  project: platform
spec:
  display:
    name: Prometheus Self-Monitoring
  duration: 1h
  datasources:
    prometheus:
      default: true
      plugin:
        kind: PrometheusDatasource
        spec:
          proxy:
            kind: HTTPProxy
            spec:
              url: http://prometheus.observability.svc.cluster.local:9090
  panels:
    samples:
      kind: Panel
      spec:
        display:
          name: Samples Appended
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: rate(prometheus_tsdb_head_samples_appended_total[5m])
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 12
            height: 6
            content:
              $ref: "#/spec/panels/samples"
```

This dashboard carries its own datasource under `spec.datasources`, so it does not depend on a project datasource. Put both files into one ConfigMap in the namespace of the server:

```sh
kubectl -n perses create configmap perses-provisioned \
  --from-file=project-platform.yaml --from-file=dashboard-platform-prometheus.yaml
```

Now tell the server to read that folder. The change adds a volume, its mount, and `provisioning` to the configuration; the rest of the resource stays as the playground created it.

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
  config:
    database:
      file:
        folder: /perses
        extension: yaml
    provisioning:
      folders:
        - /etc/perses/provisioned
  storage:
    emptyDir: {}
  resources:
    requests:
      memory: 128Mi
    limits:
      memory: 512Mi
  volumes:
    - name: provisioned
      configMap:
        name: perses-provisioned
  volumeMounts:
    - name: provisioned
      mountPath: /etc/perses/provisioned
      readOnly: true
```

Apply it:

```sh
kubectl apply -f perses-perses.yaml
```

Then check the result:

```sh
kubectl -n perses rollout status deployment/perses
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/platform/dashboards/prometheus-self | jq .spec.display'
```

The new pod read the folder when it started, and the API returns the dashboard `Prometheus Self-Monitoring` in the project `platform`. The new pod started on an empty `emptyDir`, so the dashboards the operator had synced are briefly gone; the operator writes them again when it next reconciles their objects.

## Provisioning against custom resources

Without the operator, the Perses Helm chart offers the same idea with less hand work. Its values have a `sidecar` section: when enabled, a second container (`kiwigrid/k8s-sidecar`) watches ConfigMaps labelled `perses.dev/resource: "true"`, in all namespaces by default, and writes their files into the provisioning folder. A team then ships a dashboard as a labelled ConfigMap.

The two approaches differ in where the truth lives and what you can see:

| | Custom resources and the operator | Provisioning files |
| --- | --- | --- |
| Source of truth | The `PersesDashboard` object | The file in the folder |
| Project | The namespace name, created by the operator | Must be provisioned as its own file |
| Status | Conditions on every object | None; read the server log |
| A refused dashboard | `ValidationFailed` on the object | A log line in the server |
| Who may deliver | Kubernetes RBAC on each kind and namespace | Whoever may write the ConfigMap or the folder |

You can now load resources into Perses from files and say when that is the better fit: a server without the operator, or a few fixed dashboards that must always come back. For teams that deliver their own dashboards, the custom resources give status and permissions per namespace, which provisioning does not.

## Common pitfalls

> [!WARNING]
> - **Mounting files under `/etc/perses/provisioning`.** The operator reserves that path; the API server refuses the `Perses` resource.
> - **Provisioning a dashboard without its project.** Provision the `Project` file as well, or the dashboard has nowhere to go.
> - **Expecting status for a provisioned dashboard.** Provisioning writes no conditions; read the server log with `kubectl -n perses logs deploy/perses`.
> - **Editing a provisioned dashboard in the user interface.** The next provisioning run writes the file's version back.
