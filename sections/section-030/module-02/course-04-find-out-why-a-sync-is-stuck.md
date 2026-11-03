# Find Out Why A Sync Is Stuck

A delivery that stops is the usual way GitOps fails: the commit is merged, and nothing changes. The cause is in one of four places: the source cannot fetch, the build fails, the apply is refused, or a check does not pass. This part gives an order of commands that finds the place in a minute.

## Read the status first

One command lists every source and every delivery with their last message:

<!-- astrona:playground:renew -->

```sh
flux get all -A
```

For each object the columns show the revision, whether it is suspended, whether it is ready, and a message. Start at the top of the chain. A source that is not ready explains every delivery below it, so fix that one first. The messages are specific: an authentication failure, a path that does not exist, a failed build, or a dependency that is not ready.

## Events and logs

When the message is short, the events show more. The Flux CLI collects them:

```sh
flux events --for Kustomization/ops-datasources
```

The controller log shows the same run in detail. Filter it to the one object:

```sh
flux logs --kind=Kustomization --name=ops-datasources --namespace=flux-system --since=10m
```

Errors in the log name the object that was refused and the reason that the Kubernetes API gave, for example a field that the schema rejects.

## Trace an object back to Git

Given an object in the cluster, `flux trace` finds the delivery that owns it and the source revision it came from:

```sh
flux trace --kind PersesDashboard --name payments-overview --namespace payments --api-version perses.dev/v1alpha2
```

The output lists the object, the Flux `Kustomization` that applied it, the `GitRepository`, the revision and the path. When two deliveries both claim a path, the trace shows which one actually applied it. An object that no delivery owns has no trace, which tells you it was applied by hand.

## Preview a change before pushing it

Compare a local folder with what the cluster has, without applying anything:

```sh
flux diff kustomization ops-datasources --path ./fleet/ops/datasources
```

The output is the difference between the cluster and the folder after build and substitution. It is the Flux counterpart of `kubectl diff`. A change that shows an unexpected line is stopped before the commit.

## Stop and restart a delivery

While you investigate, stop Flux from reapplying a delivery, so that your hand changes are not undone every interval:

```sh
flux suspend kustomization ops-datasources
flux get kustomizations
flux resume kustomization ops-datasources
```

A suspended delivery shows `True` in the suspended column and does not reconcile. Suspend means pause, not remove: pruning does not happen and nothing is deleted. Resume it when you finish, because a delivery left suspended is the next stuck one. `flux reconcile kustomization NAME --with-source` fetches the source and applies at once, and is the right command after a push.

## A worked order

When a change from Git does not appear:

1. `flux get sources git` for the source. A failure here is credentials, a branch name or the address.
2. `flux get kustomizations` for the delivery. A failure is the path, a build error, a failed check or a dependency.
3. `flux events` and `flux logs` for the reason.
4. `kubectl get` and the conditions of the Perses object. A delivery can be fine while Perses refuses the content.
5. `flux trace` if you doubt which delivery owns the object.

The order goes from the source of the data to the end of the chain, so the first failing step is the cause.

## Common pitfalls

> [!WARNING]
> - **Starting at the Perses object.** A failure upstream hides there. Start at the source.
> - **Leaving a delivery suspended.** It stops reconciling without any error.
> - **Reading only the first line of a message.** The reason is usually in the second half.
> - **Fixing in the cluster and not in Git.** Flux undoes it at the next interval.
