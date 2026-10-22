# Kubernetes RBAC For Perses Resources

A team's pipeline needs an identity, and that identity needs exactly enough rights to deliver the team's dashboards. Kubernetes role-based access control (RBAC) grants rights per resource kind, per verb and per namespace, and the Perses custom resources are resource kinds like any other. This part grants the `payments` team its rights, proves them from both sides, and applies a dashboard as the team.

## A ServiceAccount with no rights

A ServiceAccount is an identity for programs inside the cluster, such as a deployment pipeline or Flux acting for a team. Its full user name is `system:serviceaccount:<namespace>:<name>`. Your own `kubectl` user may impersonate other identities with `--as`, which is the way to test what another identity can do. Ask what `payments-ci` may do with dashboards today:

<!-- astrona:playground:renew -->

```sh
kubectl auth can-i create persesdashboards.perses.dev -n payments \
  --as system:serviceaccount:payments:payments-ci
```

The answer is `no`. A new ServiceAccount has no rights beyond reading basic information about the API, and RBAC only ever adds rights; there are no rules that deny.

## A Role for Perses objects, bound in one namespace

A Role lists verbs on resource kinds in one namespace. A RoleBinding gives a Role to users, groups or ServiceAccounts, in the same namespace. The Role below allows every normal verb on dashboards and datasources, in the API group `perses.dev`, and nothing else.

Save this as `rbac-payments-perses-editor.yaml`:

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
```

Apply it:

```sh
kubectl apply -f rbac-payments-perses-editor.yaml
```

Then check the result from both sides, what the team may do and what it may not:

```sh
for check in "create persesdashboards.perses.dev -n payments" \
             "create persesdashboards.perses.dev -n catalog" \
             "create persesglobaldatasources.perses.dev" \
             "patch perses.perses.dev -n perses" \
             "create rolebindings.rbac.authorization.k8s.io -n payments"; do
  printf '%-60s %s\n' "$check" "$(kubectl auth can-i $check --as system:serviceaccount:payments:payments-ci)"
done
```

Only the first line says `yes`. The team cannot write dashboards in `catalog`, cannot create a `PersesGlobalDatasource`, cannot change the `Perses` server, and cannot create RoleBindings, which would let it give itself more rights.

Each of those `no` answers protects something. A `PersesGlobalDatasource` is cluster-scoped and appears in every Perses project, so only the platform team may write one. A `Perses` object controls the server for everyone. And because the operator maps a namespace to a project, `create persesdashboards -n catalog` is the same question as "may this team write into the catalog project".

## Apply a dashboard as the team

The strongest check of a permission is to use it. Apply the team's dashboard while impersonating the ServiceAccount, once in the right namespace and once in the wrong one.

Save this as `persesdashboard-payments-overview.yaml`:

```yaml
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

Apply it as the team:

```sh
kubectl apply -f persesdashboard-payments-overview.yaml --as system:serviceaccount:payments:payments-ci
```

Then try the same file in the other team's namespace:

```sh
kubectl apply -f persesdashboard-payments-overview.yaml -n catalog --as system:serviceaccount:payments:payments-ci
```

The first apply creates the dashboard, and the operator copies it into the project `payments`. The second is refused with a `Forbidden` error from the API server, which names the user, the verb, the resource and the namespace. If the file names `namespace: payments` and you pass `-n catalog`, `kubectl` refuses before it asks the API server, because the two namespaces disagree; remove the `namespace` line from a copy of the file to see the RBAC refusal itself.

Note who did what. The API server checked the RBAC rules for the team's identity. The operator, which runs with its own broad rights, then did the Perses side. The team never talks to Perses, so its Kubernetes rights are its only rights on Perses objects delivered this way.

You can now grant a team edit rights on Perses objects in one namespace and prove them from both sides. The same rights must also hold when the team's dashboards come from Git, which is the question still open.

## Common pitfalls

> [!WARNING]
> - **Binding a ClusterRole with a ClusterRoleBinding to make a pipeline work.** That gives the team the same rights in every namespace. Use a Role and a RoleBinding per namespace.
> - **Granting `rolebindings` or `roles` to a team.** A team that can write RoleBindings can give itself any right it can reach.
> - **Testing only what should work.** Check the `no` answers too; they are the isolation.
> - **Forgetting the API group.** `persesdashboards.perses.dev` and the rule's `apiGroups: ["perses.dev"]` must match, or the rule grants nothing.

## Your mission: Keep Each Team In Its Own Namespace

You can now give a team's ServiceAccount edit rights on Perses objects in its own namespace and prove that it has no more. The graded lab gives you both team namespaces with ServiceAccounts that have no rights, and asks you to grant each team exactly those rights and to deliver each team's datasource and dashboard as the team itself.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-111-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-111-lab-040-01
astrona start ats-111-playground-040-01
```
