# Section 030: GitOps For Dashboards With Flux

Custom resources make dashboards Kubernetes objects. GitOps makes those objects files in Git, applied to the cluster by an agent that runs in it. A team then changes a dashboard with a commit, reviews it like code, and gets back any version from history. Flux is that agent here: it pulls the repository and applies each team's folder, and the Perses Operator carries the objects on into Perses.

This section comes after the custom resources, because Flux only moves objects; it does not know what a dashboard is. Two controllers now sit between a commit and a dashboard, and the skill is to say which one did what.

**Topic covered:** GitOps For Dashboards With Flux

## What you will learn

- Keeping `PersesDatasource` and `PersesDashboard` files in Git, one folder per team.
- Connecting Flux to the repository with a `GitRepository` and one Flux `Kustomization` per team.
- Following a commit through Flux, the API server and the operator into Perses.
- What happens when someone edits a dashboard object by hand, and when someone edits the dashboard inside Perses.
- How pruning removes a dashboard that was deleted from Git, and what happens when pruning is off.
- Where Argo CD fits as the other common GitOps agent.

## The learning path

The module has a landing page, two short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Reconcile Dashboards From Git

The playground runs the operator, one Perses server, Gitea with the repository `gitops/fleet`, and the Flux controllers. The repository holds the folders `dashboards/payments/` and `dashboards/catalog/`; nothing applies them yet.

1. Dashboards In Git, Applied By Flux
2. Drift, Pruning And The Operator, followed by the lab **Deliver Dashboards From Git With Flux**
3. Summary

## Section capstone: Repair A Dashboard Delivery Pipeline

The capstone is one graded scenario that combines the whole module. The dashboard pipeline has been running for a while. One team's folder is never applied, an old dashboard deleted from Git is still in Perses, and a new dashboard sits in the cluster but never appears in Perses. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-111-capstone-030
```
