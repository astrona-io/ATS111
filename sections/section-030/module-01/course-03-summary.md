# Summary

Dashboards delivered from Git pass through two controllers. This module showed how to connect Flux to a dashboards repository, which controller does which step, and how each one handles drift and deletion.

## What you learned

The repository holds one folder per team with the team's `PersesDatasource` and `PersesDashboard` files and no `Namespace` objects. Flux reads it through a `GitRepository`, which names the URL, the branch, the fetch interval and a Secret with credentials made by `flux create secret git`. It applies each folder through a Flux `Kustomization`, which names the path, the run interval and whether to prune. The Flux `Kustomization` object is not the Kustomize file `kustomization.yaml`. Flux makes the cluster match Git, and the Perses Operator makes Perses match the cluster. A commit travels from source-controller to kustomize-controller to the custom resource, and from there through the operator into Perses. `flux reconcile kustomization <name> --with-source` runs the Flux half on demand.

Drift happens at two levels. A hand edit of a `PersesDashboard` object is undone by kustomize-controller on its next run, because server-side apply puts back every field Git sets. An edit made inside Perses is invisible to Flux, because the object still matches Git, and the operator only corrects it the next time it reconciles the object. Any change to the object, such as an annotation, starts that reconciliation on demand. Argo CD has the same split: its self-heal fixes the cluster, not Perses.

Pruning deletes what Flux applied before and Git no longer holds, using the inventory in the `Kustomization`'s status. A dashboard removed from Git is pruned from the cluster, and the operator then deletes it from Perses. With `prune: false`, a file removed from Git drops out of the inventory without being deleted, and turning pruning on later does not remove it. The key facts to remember are these:

- Flux never talks to Perses, and the operator never reads Git.
- A ready Flux `Kustomization` proves the object is in the cluster; the object's conditions prove it reached Perses.
- Keep pruning on, and remove orphans by hand if it was ever off.
- Correct an edit made inside Perses by touching the object, not by running Flux.

<!-- astrona:playground:destroy -->
