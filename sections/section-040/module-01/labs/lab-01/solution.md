# Solution: Keep Each Team In Its Own Namespace

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the permission matrix for both ServiceAccounts, that no ClusterRoleBinding names them, and both teams' objects `Available` and in Perses.

## Step 1: Grant each team its rights

One file holds the Role and the RoleBinding for both teams. Save this as `rbac-perses-editors.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: perses-editor
  namespace: payments
rules:
  - apiGroups: ["perses.dev"]
    resources: ["persesdashboards", "persesdatasources"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payments-ci-perses-editor
  namespace: payments
subjects:
  - kind: ServiceAccount
    name: payments-ci
    namespace: payments
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: perses-editor
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: perses-editor
  namespace: catalog
rules:
  - apiGroups: ["perses.dev"]
    resources: ["persesdashboards", "persesdatasources"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: catalog-ci-perses-editor
  namespace: catalog
subjects:
  - kind: ServiceAccount
    name: catalog-ci
    namespace: catalog
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: perses-editor
```

Apply it:

```sh
kubectl apply -f rbac-perses-editors.yaml
```

## Step 2: Check the matrix

```sh
for team in payments catalog; do
  other=catalog; [ "$team" = catalog ] && other=payments
  as="system:serviceaccount:$team:$team-ci"
  echo "$team own dashboards:   $(kubectl auth can-i create persesdashboards.perses.dev -n "$team" --as "$as")"
  echo "$team own datasources:  $(kubectl auth can-i create persesdatasources.perses.dev -n "$team" --as "$as")"
  echo "$team other dashboards: $(kubectl auth can-i create persesdashboards.perses.dev -n "$other" --as "$as")"
  echo "$team rolebindings:     $(kubectl auth can-i create rolebindings.rbac.authorization.k8s.io -n "$team" --as "$as")"
  echo "$team global sources:   $(kubectl auth can-i create persesglobaldatasources.perses.dev --as "$as")"
done
```

Each team prints `yes` for its own dashboards and datasources and `no` for the rest.

## Step 3: Deliver each team's objects as the team

Save the payments pair as `perses-payments.yaml`:

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDatasource
metadata:
  name: prometheus
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Prometheus
    default: true
    plugin:
      kind: PrometheusDatasource
      spec:
        proxy:
          kind: HTTPProxy
          spec:
            url: http://prometheus.observability.svc.cluster.local:9090
---
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: payments-overview
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Payments Overview
    duration: 1h
    panels:
      up:
        kind: Panel
        spec:
          display:
            name: Targets Up
          plugin:
            kind: TimeSeriesChart
            spec: {}
          queries:
            - kind: TimeSeriesQuery
              spec:
                plugin:
                  kind: PrometheusTimeSeriesQuery
                  spec:
                    query: up
    layouts:
      - kind: Grid
        spec:
          display:
            title: Health
          items:
            - x: 0
              y: 0
              width: 12
              height: 6
              content:
                $ref: "#/spec/panels/up"
```

Make `perses-catalog.yaml` from it by changing `payments` to `catalog` and `Payments Overview` to `Catalog Overview`:

```sh
sed -e 's/payments/catalog/g' -e 's/Payments Overview/Catalog Overview/' perses-payments.yaml > perses-catalog.yaml
```

Apply each file as its team:

```sh
kubectl apply -f perses-payments.yaml --as system:serviceaccount:payments:payments-ci
kubectl apply -f perses-catalog.yaml --as system:serviceaccount:catalog:catalog-ci
```

## Step 4: Prove the result in Perses

```sh
for team in payments catalog; do
  kubectl -n observability exec deploy/tester -- sh -c \
    "curl -s http://perses.perses:8080/api/v1/projects/$team/dashboards/$team-overview | jq -r .spec.display.name"
done
```

Perses answers `Payments Overview` and `Catalog Overview`.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Bind the ClusterRole `cluster-admin` or `edit` with a ClusterRoleBinding | Each team can write the other's dashboards; the grader checks both the matrix and the bindings |
| Add `*` to the Role's resources | The team can also create Roles and RoleBindings in its namespace and raise its own rights |
| Apply the objects as yourself | It works, but proves nothing about the team's rights |

## Common mistakes

- Writing `perses` instead of `perses.dev` in `apiGroups`. The rule then grants nothing.
- Putting the RoleBinding's subject in the wrong namespace. A ServiceAccount subject needs its own namespace in the binding.
