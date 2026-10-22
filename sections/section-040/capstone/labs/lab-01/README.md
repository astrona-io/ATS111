---
estimated_duration: 40m
---

# Lock Down Two Tenants Delivered By Flux

- **ID:** LAB
- **Slug:** ats-111-capstone-040
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespaces `payments`, `catalog`, `flux-system`, `gitea`, `perses` and `observability`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Perses Operator v0.5.0
> documentation and source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-111-capstone-040
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-111-capstone-040`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Helm, percli, Flux, Gitea and the Perses Operator, then the starting state |
| `manifests/` | `lab-start.yaml`, `perses-instance.yaml`, `gitea.yaml`, `repo/` (seeded files), `flux-sync.yaml` (the starting Flux objects and binding) |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for the operator and the Perses server |
| `validation/` | Grading scripts, one per check |
