# Section 040: Multi-Tenant Isolation

One Perses server for many teams is cheaper and simpler than one server each. It is only safe if each team can change its own dashboards and nothing else. With the Perses Operator, a team's dashboards are Kubernetes objects in the team's namespace, so Kubernetes role-based access control (RBAC) decides who may change them, and Flux can act as each team instead of as an administrator.

This section comes last because it builds on everything before it: the custom resources, the namespace-to-project mapping, and Flux. The skill is to give each team exactly the rights it needs and to prove that it has no more.

**Topic covered:** Multi-Tenant Isolation

## What you will learn

- One namespace per team as the boundary for dashboards, datasources and Perses projects.
- Roles and RoleBindings that allow edits to `PersesDashboard` and `PersesDatasource` in one namespace.
- Checking permissions with `kubectl auth can-i` and applying objects as a team with impersonation.
- Flux `Kustomization` objects that act as a team's ServiceAccount, and the Flux lockdown options.
- Where Perses' own authentication and authorization fit, and what the operator needs when they are on.

## The learning path

The module has a landing page, two short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Isolate Teams That Share One Perses Server

The playground runs the operator, one Perses server, Gitea with `gitops/fleet`, Flux, and the namespaces `payments` and `catalog`, each with a ServiceAccount `<team>-ci` that has no rights yet.

1. Kubernetes RBAC For Perses Resources, followed by the lab **Keep Each Team In Its Own Namespace**
2. Tenant Pipelines And Perses Authorization
3. Summary

## Section capstone: Lock Down Two Tenants Delivered By Flux

The capstone is one graded scenario that combines the whole module. Flux delivers both teams' dashboards from Git, but the setup grew in a hurry: one team's pipeline runs with cluster-wide administrator rights, the other team's pipeline cannot apply anything, and a dashboard in one team's folder lands in the other team's namespace. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-111-capstone-040
```
