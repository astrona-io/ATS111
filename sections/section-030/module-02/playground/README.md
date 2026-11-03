# Operate Flux Delivery For Perses — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-111-playground-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A sandbox that spins up the Perses Operator and a Perses server, and
stays running so you can explore the module's topic. Nothing to submit.

> **Not yet run.** Written from the Perses Operator v0.5.0 documentation and
> source.

## Run it

```sh
astrona run -c .
astrona destroy ats-111-playground-030-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-111-playground-030-02`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Installs the tools, the operator and the starting state |
| `manifests/` | Prometheus and the tester pod, the Perses resource, Gitea and the seeded repository |
| `docs/overview.md` | What the environment contains and ideas to try |
