# Read-Only Mode And Server Authentication

The settings under `spec.config` of a `Perses` resource are the Perses server configuration. Some of them decide whether the server accepts writes at all, and whether a caller has to prove who it is. This part uses a throwaway server to see what a locked server does to the operator, and then explains the authentication settings, which change what the operator needs to send.

## The security block

The server configuration has a block `security`. Two of its fields matter for this module. `readonly` makes the server refuse requests that change data. `enable_auth` makes callers log in before they use the API. The block also holds the settings for sign-in providers, cookies and token lifetimes. The full list for the server version is in the Perses documentation. This part uses only `readonly`, because its effect can be seen with commands you already know.

## A server that refuses writes

Create a namespace and a server with `readonly: true`. Save this as `perses-locked.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: locked
---
apiVersion: perses.dev/v1alpha2
kind: Perses
metadata:
  name: locked
  namespace: locked
  labels:
    app.kubernetes.io/instance: locked
spec:
  image: docker.io/persesdev/perses:v0.54.0
  containerPort: 8080
  config:
    security:
      readonly: true
    database:
      file:
        folder: /perses
        extension: yaml
  storage:
    emptyDir: {}
```

Apply it:

```sh
kubectl apply -f perses-locked.yaml
```

Then check the result:

```sh
kubectl -n locked rollout status deployment/locked
kubectl -n locked get perses locked \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
```

The server runs. Ask it for its configuration and read the security block:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://locked.locked:8080/api/config | jq .security'
```

The output shows `readonly` as `true`.

## Send a dashboard to the locked server

Save this as `dashboard-for-locked.yaml`. The selector matches the locked server only:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: to-locked
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: locked
  config:
    display:
      name: To Locked
    duration: 1h
    panels: {}
    layouts: []
```

Apply it and read the condition after a short time:

```sh
kubectl apply -f dashboard-for-locked.yaml
kubectl -n payments get persesdashboard to-locked \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
```

The object exists in Kubernetes. The operator tried to write it to a server that refuses writes, so the condition is not `Available`, and the message holds what the server answered. Read the project list of the locked server to confirm that nothing arrived:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://locked.locked:8080/api/v1/projects | jq -r ".[].metadata.name"'
```

A read-only server is useful when its data comes from files that the image or a volume provides, and the API must never change it. It is not compatible with the operator, which writes through the API. Do not set it on a server the operator manages.

## What authentication changes

With `enable_auth` on, every call must carry a token, from a native Perses user or from an external provider. The operator writes through the API, so it needs credentials too. The `Perses` resource has a field `spec.client` for this. Find its options with the cluster's own schema, because they depend on the version:

```sh
kubectl explain perses.spec.client --api-version=perses.dev/v1alpha2 --recursive
```

The output lists the authentication methods the operator supports and the fields of each. A Secret holds the secret values, and the field refers to the Secret by name. Without credentials, an authenticated server answers `401` to the operator, and the objects of every team stop reaching it, so set the credentials in the same change that turns authentication on.

Authentication also changes the other callers. Dashboards that Grafana-style tools or scripts read from the API now need a token as well. Browsers sign in through the user interface.

## Clean up

Remove the throwaway server and the dashboard before you go on:

```sh
kubectl delete -f dashboard-for-locked.yaml
kubectl delete -f perses-locked.yaml
```

## Common pitfalls

> [!WARNING]
> - **Setting `readonly: true` on a server that the operator manages.** Every object stops at the condition.
> - **Turning authentication on without `spec.client`.** The operator gets `401` and delivery stops.
> - **Writing authentication secrets into `spec.config`.** Use a Secret that the client field refers to.
> - **Copying field names from another version.** Discover them with `kubectl explain` for the installed CRD.
