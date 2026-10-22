# Isolate Teams That Share One Perses Server — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-111-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A sandbox that spins up the Perses Operator and a Perses server, Gitea and Flux, and
stays running so you can explore the module's topic. Nothing to submit.

> **Not yet run.** Written from the Perses Operator v0.5.0 documentation and
> source.

## Run it

```sh
astrona run -c .
astrona destroy ats-111-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-111-playground-040-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Installs the tools, the operator and the starting state |
| `manifests/` | `lab-start.yaml`, `perses-instance.yaml`, `gitea.yaml`, `repo/` (files seeded into `gitops/fleet`) |
| `docs/overview.md` | What the environment contains and ideas to try |
