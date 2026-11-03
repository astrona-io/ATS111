# Cap What A Team Can Create

A namespace is the boundary of a team, and nothing in it limits how many objects the team creates. A pipeline with a loop bug can create dashboards until the Perses server is slow or the API server stores far more objects than anyone planned. A ResourceQuota stops that in the namespace of the team that causes it.

## Quota on custom resources

A ResourceQuota is a namespaced object whose `spec.hard` lists limits. Besides CPU and memory, Kubernetes supports an object count for any resource, including a custom resource. The key has the form `count/<resource>.<group>`. For the dashboards of the operator the key is `count/persesdashboards.perses.dev`, and for datasources it is `count/persesdatasources.perses.dev`.

The quota is checked when an object is created. An object that would take the count over the limit is refused by the API server, for every user, including a cluster administrator. Objects that already exist are not removed when a limit is lowered below the count. The namespace can only not create more.

## Put a cap on payments

The playground has the empty namespace `payments`. Save this as `quota-payments.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dashboard-cap
  namespace: payments
spec:
  hard:
    count/persesdashboards.perses.dev: "2"
    count/persesdatasources.perses.dev: "2"
```

Apply it:

```sh
kubectl apply -f quota-payments.yaml
```

Then check the result:

```sh
kubectl -n payments describe resourcequota dashboard-cap
```

The output lists each resource with `Used` and `Hard`. Right after the apply, `Used` is `0`. The values appear a moment later because a controller of Kubernetes computes the first usage.

## Create more than the cap

Save this as `dashboards-three.yaml`. It holds three small dashboards. The panels and layouts are empty:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: one
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: One
    duration: 1h
    panels: {}
    layouts: []
---
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: two
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Two
    duration: 1h
    panels: {}
    layouts: []
---
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: three
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Three
    duration: 1h
    panels: {}
    layouts: []
```

Apply it:

```sh
kubectl apply -f dashboards-three.yaml
```

`kubectl` goes through the documents in order. It creates `one` and `two`, and refuses `three` with an error that starts with `exceeded quota` and names `dashboard-cap`. Read the usage again:

```sh
kubectl -n payments describe resourcequota dashboard-cap
kubectl -n payments get persesdashboards
```

`Used` is `2` for the dashboards, and the listing holds two. The objects `one` and `two` are also in Perses, because the cap limits Kubernetes objects and the operator copies those that exist.

## What a rejection looks like in a pipeline

A pipeline that applies the files gets the same error. In Flux, the delivery that contains the refused object is not `Ready`, and its message includes the quota error. The two objects that fit are applied. The rest of the folder is not blocked. This is the reason to read the message of a stuck delivery from the top.

Delete one dashboard and apply the file again to see the third fit:

```sh
kubectl -n payments delete persesdashboard one
kubectl apply -f dashboards-three.yaml
```

After the delete, the count is `1`, so the apply creates `one` again and refuses `three` again, which makes the count `2`. A quota lets you replace objects, not exceed the number.

## Choosing a number

The right cap is a few times the number the team has today. A cap equal to the current count blocks the team the first time it adds a dashboard, and a cap far above it protects nothing. Review caps when a team asks for more, and leave a record of why.

## Common pitfalls

> [!WARNING]
> - **Writing the key as `persesdashboards`.** A custom resource needs the form `count/persesdashboards.perses.dev`.
> - **Expecting the quota to remove objects.** It only refuses new ones.
> - **Applying the quota and testing in the same second.** The first usage is computed a moment later.
> - **Capping dashboards and not datasources.** A loop can create either.
