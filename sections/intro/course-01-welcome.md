# Welcome To The Course

This course trains you for the **Kubernetes-Native Operations & The Perses Operator** part of the Astrona **Perses** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, ConfigMaps, labels, `kubectl apply`, `kubectl get` and `kubectl logs`. You have seen a Perses dashboard or a similar dashboard tool, and you know that a dashboard reads its data from a datasource such as Prometheus. You do not need to know Kubernetes operators or Flux yet. Each new idea is explained the first time it appears.

## What you can do at the end

Perses can run as a set of Kubernetes objects, so this course does not ask you to remember words. It asks you to declare objects, read their status, and find out why something does not reach the Perses server. The course has four topics, and each one turns into a set of skills you will practise.

The first topic is **the Perses Operator**. You will learn to:

- Explain what an operator is and what the Perses Operator does on every reconciliation.
- Install the operator with Helm and run a Perses server from a `Perses` resource.
- Read the `Available` and `Degraded` conditions and the operator log to find why a server does not run.

The second topic is **dashboards and datasources as Kubernetes resources**. You will learn to:

- Declare a `PersesDatasource`, a `PersesGlobalDatasource` and a `PersesDashboard`.
- Explain how a namespace becomes a Perses project and how `instanceSelector` picks the servers.
- Load resources from files without the operator, with Perses provisioning.

The third topic is **GitOps with Flux**. You will learn to:

- Deliver dashboards from a Git repository with one Flux `Kustomization` per team.
- Explain what happens when someone edits a dashboard by hand, and how pruning removes a dashboard deleted from Git.

The fourth topic is **multi-tenant isolation**. You will learn to:

- Give each team edit rights on Perses resources in its own namespace only, with Kubernetes RBAC.
- Check permissions with `kubectl auth can-i` and impersonation.
- Make each team's Flux `Kustomization` act as the team's ServiceAccount.

Everything is written for the **Perses Operator v0.5.0** and **Perses v0.54.0**.

## The words this course uses

The pages use the words of Perses, the operator, Flux and Kubernetes, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

An **operator** is a controller: a program in the cluster that watches some kinds of objects and keeps changing the cluster until it matches them. One such run is a **reconciliation**. A **custom resource** is an object of a kind that a **custom resource definition (CRD)** added to the Kubernetes API. A **status condition** is an entry in an object's `.status.conditions` that says whether it worked and why.

Four custom resources come back on almost every page:

| Kind | What it describes |
| --- | --- |
| `Perses` | One Perses server: its image, configuration, storage and Service |
| `PersesDatasource` | A datasource in the Perses project named after its namespace |
| `PersesGlobalDatasource` | A datasource every Perses project can use |
| `PersesDashboard` | A dashboard in the Perses project named after its namespace |

## The example setup in your playground

Every playground and lab runs the same small setup. The Perses Operator runs in the namespace `perses-operator`. A `Perses` resource named `perses` in the namespace `perses` runs one Perses server. Prometheus in the namespace `observability` provides the data, and a `tester` pod there sends requests to the Perses API.

Two teams use the server: `payments` and `catalog`. Each has its own namespace, a datasource named `prometheus`, and a dashboard named after the team. In the GitOps and multi-tenancy sections, a Git server called Gitea also runs inside the cluster, with the repository `gitops/fleet` that holds the teams' dashboards. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with the operator and the server, then the dashboards and datasources, then delivery from Git, and ends with keeping teams apart.

| Section | What it covers |
| --- | --- |
| 010 | Running Perses With The Perses Operator |
| 020 | Dashboards And Datasources As Kubernetes Resources |
| 030 | GitOps For Dashboards With Flux |
| 040 | Multi-Tenant Isolation |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
