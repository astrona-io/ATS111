# Variables From The Cluster

A datasource address is a value that differs by cluster: the Prometheus of a staging cluster is not the Prometheus of production. Writing it into a file in Git means one copy of the file for each cluster. Flux can instead fill values into the manifests after Kustomize has built them. This part reads the values from a ConfigMap, shows the failure when they are missing, and ends with a graded lab.

## postBuild substitution

The field `spec.postBuild` of a Flux `Kustomization` runs after the build. It has two sources of values. `substitute` is a map written in the object itself. `substituteFrom` is a list of ConfigMaps and Secrets in the namespace of the `Kustomization`, whose keys become values. Flux replaces `${name}` in every manifest with the value of `name`. A default is written `${name:=value}` and is used when the variable has no value.

Flux replaces the form with braces. Test any other form before you rely on it. Because Prometheus queries use a dollar sign for variables, as in `up{job="$job"}`, a dashboard in a folder with substitution on needs a look at the result. The command `flux diff kustomization` shows the manifests after substitution.

## Look at the file in Git

The repository holds a datasource in `ops/datasources/` whose address is a variable:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
grep -n 'url:' fleet/ops/datasources/datasource.yaml
```

The line is `url: ${PROMETHEUS_URL}`. Applied as it is, the address would be the literal text, which is not a URL.

## Deliver it without the value

The source `fleet` and the secret from the first part must exist. Save this as `flux-ops-datasources.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: ops-datasources
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: fleet
  path: ./ops/datasources
  prune: true
```

Apply it:

```sh
kubectl apply -f flux-ops-datasources.yaml
```

Then check the result:

```sh
flux reconcile kustomization ops-datasources --with-source
kubectl -n payments get persesdatasource ops-prometheus \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
```

Flux reports the delivery as applied, because the object was valid for Kubernetes. The datasource, however, is not `Available`, and its condition shows that the Perses server refused the value. This is the Perses-level validation from the earlier module, now triggered from Git. Flux was healthy and the delivery was wrong, which is why reading the object matters as much as reading Flux.

## Add the value

Create the ConfigMap with the value, in the namespace of the Flux `Kustomization`:

```sh
kubectl -n flux-system create configmap platform-vars \
  --from-literal=PROMETHEUS_URL=http://prometheus.observability.svc.cluster.local:9090
```

Now tell the Flux `Kustomization` to use it. Add this under `spec` in `flux-ops-datasources.yaml`:

```yaml
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: platform-vars
```

Apply the file again and run the delivery:

```sh
kubectl apply -f flux-ops-datasources.yaml
flux reconcile kustomization ops-datasources --with-source
kubectl -n payments get persesdatasource ops-prometheus \
  -o jsonpath='{.spec.config.plugin.spec.proxy.spec.url}{"\n"}'
```

The address is now the value from the ConfigMap. To use another address on another cluster, change the ConfigMap there, and the files stay the same. A missing key leaves the text `${PROMETHEUS_URL}` as it is, unless a default is written, and a ConfigMap that is missing makes the delivery fail unless the entry is marked `optional: true`.

## Secrets as a source

`substituteFrom` accepts a Secret in the same way. Do not put secrets in a ConfigMap, and do not commit secret values in plain text to Git. Encrypting Secrets in Git is a separate topic that this module does not cover.

## Your mission: Deliver An Ordered, Parameterised Ops Pipeline

You can now order deliveries, build overlays and fill values from the cluster. The graded lab combines them: two deliveries from the folders `ops/datasources` and `ops/dashboards`, in order, with the Prometheus address supplied from a ConfigMap and a health check on the Perses server.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-111-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-111-lab-030-02
astrona start ats-111-playground-030-02
```

## Common pitfalls

> [!WARNING]
> - **Reading a `Ready` Flux object as a working dashboard.** Flux checks the apply. Perses checks the content. Read the conditions of the object too.
> - **Putting a value in the wrong namespace.** `substituteFrom` reads the namespace of the Flux `Kustomization`.
> - **Using a variable form Flux does not replace.** The text stays as it is. Check the output with `flux diff kustomization`.
> - **Committing secrets to Git as plain text.** A Secret in `substituteFrom` is read from the cluster, not from the repository.
