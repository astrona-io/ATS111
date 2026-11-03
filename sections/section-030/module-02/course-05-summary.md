# Summary

A single `Kustomization` per folder is enough for a first delivery. A pipeline that a team can rely on adds an order, a definition of healthy, a way to share a base, a way to supply values per cluster, and a routine for finding a stuck sync.

## What you learned

`dependsOn` makes a delivery wait until the listed deliveries are `Ready`. A blocked delivery applies nothing new, deletes nothing, and tries again at its next interval. `Ready` means the apply succeeded unless `wait` or `healthChecks` add more, bounded by `timeout`, so the strictness of a dependency is the strictness of the checks of the object it waits for.

A Kustomize base with an overlay per team keeps one source for similar dashboards. Overlays change values: namespace, prefix, labels, small patches. `kubectl kustomize` shows the exact output before it is committed. Adding a `kustomization.yaml` to a folder changes which files are applied, because Flux then applies only what the file lists.

`postBuild.substituteFrom` fills `${name}` values from a ConfigMap or Secret in the namespace of the Flux `Kustomization`, so the same files run on every cluster. A delivery can be `Ready` while Perses refuses the content, so the Perses object is read as well as the Flux object.

To find a stuck sync, go from the source to the end of the chain: `flux get`, `flux events`, `flux logs`, the conditions of the Perses object, and `flux trace` for ownership. `flux diff` and `kubectl kustomize` preview a change, and `flux suspend` pauses a delivery. The key facts to remember are these:

- Without `dependsOn` there is no order.
- A blocked delivery does not delete anything.
- `kubectl kustomize` previews an overlay without a cluster.
- Substitution happens after the build, from the namespace of the Flux `Kustomization`.
- Start at the source when something does not arrive.

<!-- astrona:playground:destroy -->
