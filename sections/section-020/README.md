# Section 020: Dashboards And Datasources As Kubernetes Resources

A dashboard that lives only inside the Perses server is created by hand, changed by hand and lost by hand. With the Perses Operator, a dashboard and the datasource it reads can be Kubernetes objects instead: `PersesDashboard` and `PersesDatasource`, next to the application they describe. The operator copies them into Perses and keeps the copy in line with the object.

This section comes right after the operator, because a team's dashboard is the reason most people run the operator at all. It shows how a namespace becomes a Perses project, how an object finds the servers it belongs to, and what Perses does when it refuses a dashboard.

**Topic covered:** Dashboards And Datasources As Kubernetes Resources

## What you will learn

- Declaring a `PersesDatasource` and a `PersesGlobalDatasource`, and when each one fits.
- Declaring a `PersesDashboard`, and how its `spec.config` maps to a Perses dashboard.
- How the operator turns the namespace of an object into a Perses project.
- How `instanceSelector` picks the Perses servers, and which labels it reads.
- What the operator does when you change or delete an object, and when Perses refuses a dashboard.
- Loading resources from files with Perses provisioning, the way without the operator.

## The learning path

The module has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Declare Dashboards And Datasources In Namespaces

The playground runs the operator, one Perses server, Prometheus, and the empty namespaces `payments` and `catalog`.

1. Datasources As Custom Resources
2. Dashboards As Custom Resources, followed by the lab **Give Two Teams Their Own Dashboards**
3. Provisioning Without The Operator
4. Summary

## Section capstone: Fix Dashboards That Never Reach Perses

The capstone is one graded scenario that combines the whole module. Both teams declared their dashboards and datasources, and the platform team rebuilt the Perses server. None of the `payments` objects reach Perses, one `catalog` dashboard is refused, and the `catalog` datasource returns no data. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-111-capstone-020
```
