# Isolate Teams That Share One Perses Server

Two teams share one Perses server. If either team's pipeline can write any dashboard object in the cluster, a mistake in one team's repository can overwrite the other team's dashboards, or add a datasource that every project sees. The boundary already exists in the cluster: the namespace. The operator turns each namespace into its own Perses project, so Kubernetes permissions on a namespace become permissions on a project.

Keep one sentence in mind: **a team may write Perses objects in its own namespace, and nowhere else.** Everything in this module grants that, proves it, or makes a pipeline obey it.

The module has two parts. **Kubernetes RBAC For Perses Resources** gives each team's ServiceAccount the right to edit dashboards and datasources in its own namespace, and proves it with `kubectl auth can-i` and an apply as the team. **Tenant Pipelines And Perses Authorization** makes a Flux `Kustomization` act as the team, explains the Flux lockdown options, and places Perses' own login and roles next to Kubernetes RBAC. A graded lab follows the first part.

## Learning objectives

After this module you can:

- Write a Role and a RoleBinding that let one ServiceAccount edit `PersesDashboard` and `PersesDatasource` objects in one namespace.
- Check a permission with `kubectl auth can-i --as` and apply an object as a ServiceAccount.
- Explain why `PersesGlobalDatasource` and `Perses` objects belong to the platform team only.
- Make a Flux `Kustomization` act as a team's ServiceAccount with `spec.serviceAccountName`.
- Name the Flux lockdown options and what each one prevents.
- Explain what Perses authentication changes for users and for the operator.

## Before you start

You need Kubernetes basics, the idea of a ServiceAccount (an identity for programs inside the cluster), and the `PersesDashboard` and `PersesDatasource` objects: a dashboard or datasource declared in a namespace, which the operator copies into the Perses project with the same name. Flux objects are explained when they appear.

Your playground is a single-node `kind` cluster with the **Perses Operator v0.5.0** and a Perses server (**Perses v0.54.0**) at `http://perses.perses:8080`. The namespaces `payments` and `catalog` each hold a ServiceAccount, `payments-ci` and `catalog-ci`, with no permissions. Gitea runs with the repository `gitops/fleet`, and the **Flux v2.9.6** controllers run in `flux-system`. Your own `kubectl` user is a cluster administrator, which is what lets you test other identities with `--as`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
