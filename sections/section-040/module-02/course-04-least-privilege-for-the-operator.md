# Least Privilege For The Operator

The operator is a program with an identity in the cluster, and it holds rights that a team's ServiceAccount does not. Knowing what those rights are tells you what a compromise of the operator would allow, and what you can safely accept from a chart. This part reads the rights of the operator and tests them.

## Find the identity

The operator runs in the namespace `perses-operator`. Its Deployment names the ServiceAccount it runs as:

<!-- astrona:playground:renew -->

```sh
kubectl -n perses-operator get deployments
kubectl -n perses-operator get deployment -o jsonpath='{.items[0].spec.template.spec.serviceAccountName}{"\n"}'
```

The second command prints the name of the ServiceAccount. Keep it for the next commands.

## Read what it may do

The Helm chart creates ClusterRoles and ClusterRoleBindings for that account. List the ones that mention Perses:

```sh
kubectl get clusterrole,clusterrolebinding | grep -i perses
```

Print the rules of the role that the binding points to. Replace the name with the one from the listing:

```sh
kubectl describe clusterrole <name-from-the-listing>
```

The rules list resources and verbs. Expect to see the Perses resources of the group `perses.dev` with the verbs to read and change them and their status, and the built-in resources the operator needs to run a server: Deployments, StatefulSets, Services, ConfigMaps and Secrets. Read them as a list of what the operator can do in every namespace.

## Test it with can-i

The Kubernetes API tells what an identity may do. Replace the account name with the one you found:

```sh
SA=system:serviceaccount:perses-operator:<name-from-the-deployment>
kubectl auth can-i create deployments -n perses --as "$SA"
kubectl auth can-i get secrets -n payments --as "$SA"
kubectl auth can-i delete namespaces --as "$SA"
kubectl auth can-i --list -n perses --as "$SA" | head -30
```

Each of the first three answers `yes` or `no`, and the last prints the rules in effect in the namespace. The answers show what the chart gave the operator. If the operator can read Secrets in every namespace, a compromise of it exposes them, and that is a trade you accept or narrow.

## Narrowing the rights

A chart's ClusterRole is a default for every installation. If the policy of your organisation does not accept a cluster-wide right, the options are limited and each has a cost:

- Install the operator from the chart with values that change what it creates, if the chart exposes them. Read the chart's values with `helm show values` first.
- Replace the ClusterRole with a narrower one that you maintain. The operator then breaks the first time a new version needs a right you left out, so the role must be reviewed at every upgrade.
- Accept the chart's rights and limit the operator's reach with a NetworkPolicy and with the controls on who may install a workload in `perses-operator`.

The operator also needs to reach the servers it manages. The network policy of the previous parts must list its namespace.

## Who may change the operator

The operator's namespace is part of the platform. Team ServiceAccounts must not be able to edit Deployments, ConfigMaps or Secrets there. Test it for a team:

```sh
kubectl auth can-i patch deployments -n perses-operator --as system:serviceaccount:payments:payments-ci
kubectl auth can-i create persesglobaldatasources.perses.dev --as system:serviceaccount:payments:payments-ci
```

Both answer `no`. A `yes` means a binding is wider than intended, and the earlier module showed how to find it.

## What to record

A hardened install has a short record that someone can read:

| Item | Where it comes from |
| --- | --- |
| The version of the operator and the chart | `helm list -n perses-operator` |
| The rights of the operator | `kubectl describe clusterrole` |
| The callers allowed to reach each server | The NetworkPolicy of its namespace |
| The caps per team | The ResourceQuota of each namespace |

Keeping these files in Git next to the dashboards gives the platform team one place to review a change to the limits.

## Common pitfalls

> [!WARNING]
> - **Reading only the role name.** The rules are what matter. Print them.
> - **Narrowing the ClusterRole once and never reviewing it.** An upgrade can need a right you removed.
> - **Letting a team bind to the operator's namespace.** A write there is a write to the platform.
> - **Treating a `no` for yourself as proof.** Test with `--as` for the identity you are asking about.
