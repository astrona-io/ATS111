# Solution: Cap A Team And Limit The Callers Of The Server

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the two quotas, that the cap is enforced in `payments`, that the operator can still deliver, and the NetworkPolicy.

## Step 1: Write the quotas and the policy

Save this as `limits.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dashboard-cap
  namespace: payments
spec:
  hard:
    count/persesdashboards.perses.dev: "2"
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dashboard-cap
  namespace: catalog
spec:
  hard:
    count/persesdashboards.perses.dev: "3"
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: perses-ingress
  namespace: perses
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: perses-operator
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: observability
      ports:
        - protocol: TCP
          port: 8080
```

Apply it:

```sh
kubectl apply -f limits.yaml
```

## Step 2: Check the quota usage

```sh
kubectl -n payments describe resourcequota dashboard-cap
```

After a few seconds `Used` shows `1` for the dashboards and `Hard` shows `2`.

## Step 3: Check the cap and the operator

Create a second dashboard, which fits, and a third, which does not:

```sh
kubectl -n payments apply -f - <<'EOT'
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: second
  namespace: payments
spec:
  instanceSelector:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Second
    duration: 1h
    panels: {}
    layouts: []
EOT
```

The command succeeds, and a minute later `Available` is `True` on `second`. Repeat it with the name `third`. The command fails with `exceeded quota`. Delete `second` when you are done, so the grader starts from the same count.

## Step 4: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| The key `persesdashboards` | The API server rejects the quota or ignores the resource |
| A policy that lists only `observability` | The operator cannot write, and new dashboards never become `Available` |
| A policy without a port | Every port is open to the two namespaces, and the task asks for one |

## Common mistakes

- Setting the quota to `1` because one dashboard exists. The task asks for room for exactly one more.
- Selecting namespaces by names in `matchLabels` without the `kubernetes.io/metadata.name` key.
- Forgetting `policyTypes: [Ingress]`. Without it the rule may not apply as intended.
