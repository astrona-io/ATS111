# Summary

One Perses server can serve many teams safely when each team can change only its own dashboards. This module showed how namespaces, Kubernetes RBAC and Flux impersonation draw that boundary, and where Perses' own roles fit.

## What you learned

The Perses Operator turns each namespace into a Perses project, so permissions on a namespace become permissions on a project. A Role lists verbs on resource kinds in one namespace, and a RoleBinding gives it to a ServiceAccount there. A Role with every normal verb on `persesdashboards` and `persesdatasources` in the API group `perses.dev` lets a team deliver its own dashboards and datasources. Keep `PersesGlobalDatasource` (seen by every project), `Perses` (the server itself) and RBAC objects with the platform team. `kubectl auth can-i --as system:serviceaccount:<namespace>:<name>` checks one permission, and `kubectl apply --as` uses it. The `no` answers are the isolation, so check them too.

A Flux `Kustomization` with `spec.serviceAccountName` makes kustomize-controller apply and prune as that ServiceAccount. Flux looks the ServiceAccount up in the `Kustomization`'s own namespace, so team `Kustomization` objects live in team namespaces. A file in a team's folder that targets another namespace then fails with `Forbidden`, and nothing outside the team's namespace changes. The Flux lockdown flags make that the default: `--default-service-account`, `--no-cross-namespace-refs` and `--no-remote-bases`. With cross-namespace references off, each team needs its own `GitRepository`.

Perses has a separate layer for people. With authentication on, users log in, and Perses `Role`, `RoleBinding`, `GlobalRole` and `GlobalRoleBinding` resources decide what they may do inside the server. The operator must then log in as well, through `spec.client` on the `Perses` resource. The key facts to remember are these:

- A team gets a Role and a RoleBinding in its own namespace, never a ClusterRoleBinding.
- A team that can write RoleBindings can give itself any right.
- Impersonation only protects `Kustomization` objects that set `serviceAccountName`; the lockdown flags protect the rest.
- Kubernetes RBAC controls the custom resources, and Perses roles control the user interface.

<!-- astrona:playground:destroy -->
