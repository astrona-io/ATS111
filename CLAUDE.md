# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS111 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Kubernetes-Native Operations & The Perses
  Operator** domain of the **Perses** training path (`ATP021`). It is 15% of
  the path. There is no official Perses certification exam; the path's domains
  and weights are Astrona's own, set in `ATP021/path.yaml`.
- **What the domain really tests:** running Perses and its dashboards as
  Kubernetes objects: install the operator, run a Perses server from a `Perses`
  resource, declare datasources and dashboards in application namespaces,
  deliver them from Git with Flux, and keep teams apart with Kubernetes RBAC.
  Every explanation should lead to a command they can run, and every fix
  should be proved with a resource that the Perses API serves and a status
  condition that says `Available`.
- **The four topics:** the operator and the `Perses` resource, dashboards and
  datasources as custom resources, GitOps with Flux, and multi-tenant
  isolation.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Running Perses With The Perses Operator | Operator |
  | 020 | Dashboards And Datasources As Kubernetes Resources | Custom resources |
  | 030 | GitOps For Dashboards With Flux | GitOps |
  | 040 | Multi-Tenant Isolation | Multi-tenancy |

- **The versions:** **Perses Operator v0.5.0** (image
  `docker.io/persesdev/perses-operator:v0.5.0`), installed with the
  `perses-operator` Helm chart **0.5.0** and Helm **3.22.1**. The operator's
  default Perses image is `docker.io/persesdev/perses:v0.54.0`, which matches
  the path's pin; every `Perses` resource in this repository still sets
  `spec.image` to that tag explicitly. `percli` **v0.54.0**, Flux **v2.9.6**,
  Gitea **28.2.0** (rootless), Prometheus **v3.15.1**, on a single-node `kind`
  cluster. Perses and the operator are pre-1.0: names and fields can change
  between minor releases.
- **The main sources:** the operator's user guide and API reference
  (<https://perses.dev/perses-operator/docs/user-guide/>,
  <https://perses.dev/perses-operator/docs/api/>), the chart
  (<https://github.com/perses/helm-charts>, `charts/perses-operator`), and the
  operator source at tag `v0.5.0`. The user guide mixes `v1alpha1` and
  `v1alpha2` examples; this repository uses **`v1alpha2` only** (see below).

### Status: built, not yet run

The first version of this repository was written from the documentation and
the operator source at `v0.5.0` **without a live run**. No playground or lab
has been started, and no `astrona test` has passed yet. Until a maintainer
runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The most important unverified points, in order:

1. That a query through the datasource proxy works without
   `allowedEndpoints`. The path itself is documented
   (`/proxy/projects/<project>/datasources/<name>/<datasource API path>`);
   several graders call `.../api/v1/query?query=up` on it to prove a
   datasource works.
2. That the chart installs and the operator starts with
   `certManager.enable=false` (the chart then generates its own webhook
   certificate; only `v1alpha2` resources work).
3. Flux's basic authentication to Gitea over plain HTTP (the same open risk
   as ATS094).
4. That the shared `rewrite stop` CoreDNS function writes valid blocks for
   two host names in one Corefile.

### Facts read from the operator source (tag `v0.5.0`)

These come from the code, not the user guide. Keep them exact.

- **Kinds:** `Perses`, `PersesDashboard`, `PersesDatasource` (namespaced) and
  `PersesGlobalDatasource` (cluster-scoped), all `perses.dev/v1alpha2`.
  Dashboard and datasource content goes under `spec.config`.
- **Without cert-manager**, the chart generates a self-signed certificate for
  the webhook server and the `v1alpha1` ↔ `v1alpha2` conversion webhooks are
  off, so only `v1alpha2` objects can be used.
- **The operator reaches each Perses server at**
  `http://<Perses name>.<namespace>.svc.cluster.local:<containerPort>` (plus
  `config.api_prefix`). It uses the name of the `Perses` object, **not**
  `spec.service.name`. Renaming the Service breaks every dashboard sync with
  reason `PersesConnectionFailed`.
- **Workload kind:** a file database with `spec.storage.emptyDir` gives a
  Deployment; a file database without `emptyDir` gives a StatefulSet with a
  PersistentVolumeClaim. Both are named after the `Perses` object.
- **Status:** conditions `Available` and `Degraded`. The `Perses` object gets
  `Available=True` once the operator has created its objects; it does **not**
  wait for the pod to be ready. Prove a server with the Deployment's ready
  replicas and an API request, not with the condition alone.
- **Volume check:** a `volumeMount` naming a volume that is not in
  `spec.volumes` sets `Degraded=True` with reason `InvalidConfiguration`, and
  nothing is created.
- **Reasons on dashboards and datasources:** `PersesMissing` (no `Perses`
  object matches the `instanceSelector`; retried every minute),
  `PersesConnectionFailed`, `ValidationFailed` (the Perses server refused the
  dashboard), `PersesBackendError`.
- **`instanceSelector`** is a label selector over **`Perses` objects' own
  `metadata.labels`**. Labels under `spec.metadata.labels` go only on the
  pods, Service and Deployment. An empty selector matches every `Perses`
  object in the cluster. The upstream samples select
  `app.kubernetes.io/instance` without setting it on the object; this
  repository sets `app.kubernetes.io/instance: perses` on the object.
- **Namespace → project:** the operator creates a Perses project named after
  the namespace of each dashboard or datasource, if it is missing. Deleting
  the custom resources does not delete the project.
- **Sync direction:** the operator watches the custom resources and the
  `Perses` objects, never the Perses server. A change made through the Perses
  API or user interface stays until the custom resource is reconciled again
  (any change to the object, an operator restart, or the next resync), and
  then the operator overwrites it. Deleting a custom resource deletes the
  dashboard or datasource from every selected Perses server.
- **Secrets:** the operator only watches Kubernetes Secrets labelled
  `perses.dev/watch: "true"` for changes; it can still read any Secret a
  resource names.
- **Tags:** the annotation `perses.dev/tags: "a,b"` becomes lower-case tags on
  the Perses resource.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Operator | A controller that installs and runs an application from custom resources and keeps it in the declared state |
| Custom resource definition (CRD) | A schema that adds a resource kind, such as `PersesDashboard`, to the Kubernetes API |
| Reconciliation | One run of a controller that compares the declared object with the real state and changes the real state to match |
| `Perses` resource | The custom resource that describes one Perses server: image, configuration, storage, Service |
| `PersesDashboard` / `PersesDatasource` | A dashboard / a project datasource declared in a namespace; the operator copies it into the Perses project with the namespace's name |
| `PersesGlobalDatasource` | A cluster-scoped datasource that every Perses project can use |
| `instanceSelector` | A label selector that says which `Perses` servers receive a dashboard or datasource |
| Status condition | A `type`/`status`/`reason`/`message` entry in `.status.conditions`; here `Available` and `Degraded` |
| GitOps | Running a system from a desired state kept in Git, which an agent such as Flux pulls and applies continuously |
| Flux `Kustomization` | The Flux object that applies one folder of a Git repository to the cluster; not the Kustomize file `kustomization.yaml` |
| Role / RoleBinding | Kubernetes permissions inside one namespace / who gets them |
| Impersonation | Acting as another user or ServiceAccount, with `kubectl --as` or Flux's `spec.serviceAccountName` |

### The example workloads

| Name | What it is |
| --- | --- |
| Perses Operator (namespace `perses-operator`, Helm release `perses-operator`) | Operator v0.5.0 with `certManager.enable=false` and the chart's test framework off |
| `Perses` object `perses` (namespace `perses`) | Label `app.kubernetes.io/instance: perses`, image `persesdev/perses:v0.54.0`, file database, `emptyDir` storage, port `8080`. Its Service is `perses`, so the server answers at `http://perses.perses:8080` |
| Prometheus (namespace `observability`) | `prom/prometheus:v3.15.1`, Service `prometheus` on port `9090`; it scrapes itself |
| `tester` (namespace `observability`) | `nicolaka/netshoot:v0.13` with `curl` and `jq`; graders call the Perses API from here |
| Team namespaces `payments` and `catalog` | Each holds a `PersesDatasource` named `prometheus` and a `PersesDashboard` named `<team>-overview` |
| Gitea (namespace `gitea`, sections 030 and 040) | `gitea/gitea:28.2.0-rootless` with the repository `gitops/fleet`, as in ATS094; folders `dashboards/payments/` and `dashboards/catalog/` |
| ServiceAccounts `payments-ci` and `catalog-ci` (section 040) | One per team namespace; the identity a team's pipeline or Flux `Kustomization` uses |

### Environment facts the text must respect

- **Two addresses, one pattern.** `http://perses.localtest.me:8080` and
  `http://gitea.localtest.me:3000` work both inside the cluster (a CoreDNS
  `rewrite stop` block per name, with the answer name rewritten back) and on
  the reader's machine (a port-forward each). The shared bootstrap has an
  `add_coredns_rewrite HOST TARGET` function; never write the one-line
  `rewrite name` form.
- **Graders talk to `http://perses.perses:8080` from `tester`**, so they do
  not depend on the reader's port-forward.
- **The operator is installed by Helm in every environment.** Labs that are
  about a broken `Perses` object apply that object in the seed; all others
  apply `manifests/perses-instance.yaml`.
- **Flux objects for tenants live in the tenant's namespace.** Flux looks up
  `spec.serviceAccountName` in the namespace of the `Kustomization`, so the
  section 040 `Kustomization` objects sit in `payments` and `catalog` and
  reference the `GitRepository` in `flux-system`.
- **The team folders in Git hold no `Namespace` objects.** The platform
  creates the namespaces in the bootstrap, so a team identity never needs
  cluster-wide rights.
- **Many environments start broken on purpose.** The fault is the material.
  Never "fix" it in the bootstrap.

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`), labs
(`config.yaml`, `README.md`, `prerequisites.md`, `question.md`,
`solution.md`, `bootstrap/01-install-perses-operator.sh`,
`bootstrap/02-seed-state.sh`, `manifests/`, `solution/apply.sh`,
`testing/wait-for-perses.sh`, `validation/validate-*.sh`) and one capstone per
section.

The shared plumbing (bootstrap, seed, testing, solution and validation
scripts, `config.yaml` files, manifests, repository seeds, author READMEs and
`prerequisites.md`) was generated from one script outside the repository.
When you change a shared piece (the install script, the CoreDNS function, the
canonical manifests), change it in every environment.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS111`, domain `Kubernetes-Native Operations & The
Perses Operator`, weight `15`. Lab entries carry `title`, `path`,
`difficulty`, `estimated_duration`, `topic`, `task_kind`, `tags`,
`learning_goals`, `resources`, in that order, as in ATS016.

- `topic`: exactly one of `operator`, `custom-resources`, `gitops`,
  `multi-tenancy`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `perses-operator`, `helm-chart`,
  `crd`, `reconciliation`, `status-conditions`, `operator-logs`,
  `perses-cr`, `perses-dashboard`, `perses-datasource`,
  `perses-global-datasource`, `instance-selector`, `namespace-project`,
  `server-validation`, `provisioning`, `flux`, `gitrepository`,
  `kustomization`, `prune`, `drift`, `gitea`, `rbac`, `role`,
  `role-binding`, `service-account`, `impersonation`, `can-i`.
- `resources`: 1 to 4 pages on `perses.dev`, `fluxcd.io` or `kubernetes.io`. The only place
  outside links are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-010/module-01/playground
astrona destroy ats-111-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-111-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-111-playground-<section>-<module>`, `ats-111-lab-<section>-<module>`,
`ats-111-capstone-<section>`. Graders check **behaviour** (the Perses API
returns the dashboard, a query through the datasource proxy returns data, a
change pushed to Git reaches Perses, `kubectl auth can-i` gives the expected
answer) and reject the plausible but wrong fix (deleting and recreating the
`Perses` object, removing an `instanceSelector`, creating the dashboard
through the Perses API instead of a custom resource, granting `cluster-admin`).
A lab's `question.md` and `solution.md` must match what its `validation/`
scripts check.

Test clusters on the maintainer's machine: one at a time. Sections 030 and 040
run Gitea and Flux next to the operator and Perses; allow about 4 GiB.

### Where to find trusted sources

- **Operator:** [user guide](https://perses.dev/perses-operator/docs/user-guide/),
  [API reference](https://perses.dev/perses-operator/docs/api/), the chart
  README in `perses/helm-charts`, the source at `v0.5.0`
- **Perses:** [overview](https://perses.dev/perses/docs/overview/),
  [dashboard API](https://perses.dev/perses/docs/api/dashboard/),
  [datasource API](https://perses.dev/perses/docs/api/datasource/),
  [provisioning](https://perses.dev/perses/docs/configuration/provisioning/)
- **Flux:** as in ATS094 ([Kustomization API](https://fluxcd.io/flux/components/kustomize/kustomizations/),
  [multi-tenancy](https://fluxcd.io/flux/installation/configuration/multitenancy/))
- **Kubernetes RBAC:** the Kubernetes documentation on RBAC authorization
- **The landscape:** <https://www.cncf.io/projects/perses/> (sandbox).
