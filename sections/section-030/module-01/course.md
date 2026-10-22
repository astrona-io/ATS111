# Reconcile Dashboards From Git

A dashboard object applied with `kubectl` lives as long as nobody changes it by hand, and nobody remembers who applied which version. Keeping the objects in Git fixes both: every version is a commit, and an agent in the cluster applies the repository again and again. GitOps is that practice: running a system from a desired state kept in Git, which a software agent pulls and applies continuously.

Two controllers now share the work, and keeping them apart is the skill. Keep one sentence in mind: **Flux makes the cluster match Git, and the operator makes Perses match the cluster.** Flux never talks to Perses, and the operator never reads Git.

The module has two parts. **Dashboards In Git, Applied By Flux** connects Flux to the repository with one `Kustomization` per team and follows a commit all the way into Perses. **Drift, Pruning And The Operator** changes a dashboard behind Flux's back, at two different levels, and deletes one from Git to see pruning work. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Lay out dashboards and datasources in Git, one folder per team.
- Create a `GitRepository` with credentials and a Flux `Kustomization` per team folder.
- Follow a commit through Flux, the API server and the operator, and say which component did each step.
- Predict what happens to a hand edit of a `PersesDashboard` object, and to an edit made inside Perses.
- Explain pruning, the inventory, and what a dashboard deleted from Git leaves behind when pruning is off.
- Name the Argo CD equivalents of the Flux objects.

## Before you start

You need Git from the terminal (clone, commit, push), Kubernetes basics, and the `PersesDashboard` and `PersesDatasource` objects: a dashboard or datasource declared in a namespace, which the Perses Operator copies into the Perses project with the same name. You do not need to know Flux in depth; each Flux object is explained when it appears.

Your playground is a single-node `kind` cluster with the **Perses Operator v0.5.0** and a Perses server (**Perses v0.54.0**) at `http://perses.perses:8080`. Gitea runs in the namespace `gitea` with the repository `gitops/fleet`, and the **Flux v2.9.6** controllers run in `flux-system`. The namespaces `payments` and `catalog` exist and are empty. The Flux CLI, Helm and `percli` are on your PATH.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
