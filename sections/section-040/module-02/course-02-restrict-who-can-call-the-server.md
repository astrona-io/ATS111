# Restrict Who Can Call The Server

Any pod in the cluster can reach the Perses Service on port 8080 unless something says otherwise. The server has an API that creates projects, dashboards and datasources, and a proxy that forwards queries to Prometheus. Kubernetes RBAC does not apply to those requests, because they do not go through the Kubernetes API. A NetworkPolicy does apply, and this part writes one.

## What a NetworkPolicy does

A NetworkPolicy selects pods in its namespace with `podSelector`. For those pods, it lists allowed `ingress` sources and, optionally, allowed `egress` destinations. When a pod is selected by a policy for a direction, all traffic in that direction that no policy allows is dropped. A pod that no policy selects accepts everything.

The policy is only a request to the network plugin. A cluster whose plugin does not enforce NetworkPolicy accepts the object and ignores it. Check the plugin of your cluster before you rely on a policy, and test with a request from a pod that should be refused. The `kind` default plugin may or may not enforce policies depending on its version, so the commands below show how to test and do not assume the result.

## Know who calls the server

Writing a policy needs a list of callers. In this setup they are:

- The operator, in the namespace `perses-operator`. It writes dashboards and datasources through the API.
- The tester pod in `observability`, and in a real cluster the ingress controller or the users' browsers through an ingress.
- Nothing from the team namespaces. A team changes objects in Kubernetes. It does not call the server directly.

Namespaces have the automatic label `kubernetes.io/metadata.name` with their own name, which is what a policy selects on.

## Write the policy

Save this as `networkpolicy-perses.yaml`:

<!-- astrona:playground:renew -->

```yaml
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
kubectl apply -f networkpolicy-perses.yaml
```

Then check the result:

```sh
kubectl -n perses describe networkpolicy perses-ingress
```

The description lists the selected pods (all pods in the namespace) and the two allowed sources on port 8080. Only the TCP port is open, and no other namespace is.

## Test what is allowed and what is not

An allowed caller still works. Read the projects from the tester pod:

```sh
kubectl -n observability exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
  http://perses.perses:8080/api/v1/projects
```

The status is `200`. Check that the operator can still write. Change an annotation on a dashboard from the previous part, which makes the operator sync it again, and read its condition:

```sh
kubectl -n payments annotate persesdashboard two checked-at="$(date +%s)" --overwrite
sleep 10
kubectl -n payments get persesdashboard two \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
```

If the dashboard `two` does not exist, create any dashboard in the namespace first. `Available` is `True` after a short time. A policy that blocks the operator is the mistake that breaks delivery, and it shows as the condition never becoming `Available`, or as a dashboard that is in the cluster and not in Perses.

Now start a pod in a namespace that the policy does not list and call the server:

```sh
kubectl -n catalog run probe --image=nicolaka/netshoot:v0.13 --restart=Never --rm -i --command -- \
  curl -s -m 5 -o /dev/null -w '%{http_code}\n' http://perses.perses:8080/api/v1/projects
```

On a cluster that enforces policies the request times out, and the printed status is `000`. On a cluster that does not, the status is `200`, and the policy has no effect. Both results are information about the cluster, not about your policy. The answer `000` is the one you want for the namespaces that are not listed.

## Egress and the other direction

The policy above restricts who can reach the server. The server also reaches Prometheus for the proxy. A matching egress policy would list Prometheus only, so a compromised server could not call other destinations. If you add an egress policy, remember DNS: the pods need to reach the cluster DNS service on port 53, or no name resolves.

## Your mission: Cap A Team And Limit The Callers Of The Server

You can now cap the objects a team creates and restrict who may call the server. The graded lab asks for both. A quota for each team, a policy for the server namespace, and proof that the operator still works.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-111-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-111-lab-040-02
astrona start ats-111-playground-040-02
```

## Common pitfalls

> [!WARNING]
> - **Leaving the operator's namespace out of the list.** Delivery stops without an error on the policy.
> - **Trusting a policy on a cluster that does not enforce them.** Test with a pod that should be refused.
> - **Forgetting DNS when writing egress rules.** No name resolves and every request fails.
> - **Selecting namespaces by a label you set yourself.** The automatic label `kubernetes.io/metadata.name` cannot be missing.
