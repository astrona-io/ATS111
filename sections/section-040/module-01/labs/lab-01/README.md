---
estimated_duration: 25m
---

# Keep Each Team In Its Own Namespace

- **ID:** LAB
- **Slug:** ats-111-lab-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespaces `payments`, `catalog`, `perses` and `observability`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Perses Operator v0.5.0
> documentation and source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-111-lab-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-111-lab-040-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Helm, percli and the Perses Operator, then the starting state |
| `manifests/` | `lab-start.yaml`, `perses-instance.yaml` |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for the operator and the Perses server |
| `validation/` | Grading scripts, one per check |
