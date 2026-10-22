# ATS111 — Kubernetes-Native Operations & The Perses Operator (Perses)

Course material for the **Kubernetes-Native Operations & The Perses Operator**
domain of the Astrona Perses training path
([ATP021](https://github.com/astrona-io/ATP021)), which is **15% of the path**.
Written for the **Perses Operator v0.5.0** and **Perses v0.54.0**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the operator's documentation and its source at `v0.5.0`. None has been
> started on a cluster, and no lab has passed `astrona test` yet. See
> `CLAUDE.md` for the open risks.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **A module** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining the section into a single
  scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Running Perses With The Perses Operator | 1 | 1 + capstone | Operator |
| [020](sections/section-020) | Dashboards And Datasources As Kubernetes Resources | 1 | 1 + capstone | Custom resources |
| [030](sections/section-030) | GitOps For Dashboards With Flux | 1 | 1 + capstone | GitOps |
| [040](sections/section-040) | Multi-Tenant Isolation | 1 | 1 + capstone | Multi-tenancy |

The order goes from the server to the teams. Section 010 runs the Perses
server from a `Perses` resource. Section 020 declares the teams' dashboards
and datasources as custom resources. Section 030 delivers those resources from
Git with Flux, and section 040 keeps the teams apart with namespaces, RBAC and
Flux impersonation.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Run Perses With The Perses Operator](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Declare Dashboards And Datasources In Namespaces](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Reconcile Dashboards From Git](sections/section-030/module-01/course.md) | 2 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Isolate Teams That Share One Perses Server](sections/section-040/module-01/course.md) | 2 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Make The Operator Reach Its Perses Server | a renamed Service the operator cannot reach, a 16Mi memory limit |
| [020](sections/section-020/capstone/labs/lab-01) | Fix Dashboards That Never Reach Perses | the selector label only under `spec.metadata.labels`, a layout pointing at a missing panel, a datasource URL in the wrong namespace |
| [030](sections/section-030/capstone/labs/lab-01) | Repair A Dashboard Delivery Pipeline | a wrong Flux path, pruning off with an orphaned dashboard, a dashboard Perses refuses |
| [040](sections/section-040/capstone/labs/lab-01) | Lock Down Two Tenants Delivered By Flux | a missing RoleBinding, no impersonation, a cluster-admin binding, a cross-namespace dashboard in Git |

---

## The lab environment

Every playground and lab is a **kind** cluster with:

- the Perses Operator v0.5.0, installed with the `perses-operator` Helm chart
  0.5.0 (`certManager.enable=false`, so only `perses.dev/v1alpha2` objects);
- a `Perses` resource `perses` in the namespace `perses` (except where the lab
  is about a broken one), serving at `http://perses.perses:8080` and, through
  `kubectl -n perses port-forward svc/perses 8080:8080`, at
  `http://perses.localtest.me:8080`;
- Prometheus v3.15.1 and a `tester` pod in the namespace `observability`;
- in sections 030 and 040, Gitea (`gitops/fleet`) and Flux v2.9.6, set up
  the same way as in the first course of the FluxCD path.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/<section>/module-01/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/<section>/module-01/labs/lab-01
astrona submit -c sections/<section>/module-01/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** with independent checks, and several of
them reject the plausible-but-wrong fix (deleting and recreating the `Perses`
resource, removing an `instanceSelector`, creating dashboards through the Perses
API, granting `cluster-admin`).
