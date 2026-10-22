# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Running Perses With The Perses Operator

## Scenario

A colleague moved the team's Perses server to the Perses Operator. They wrote a `Perses` resource named `perses` in the namespace `perses`, applied it, and went home. The server never answered. The resource also mounts the ConfigMap `perses-extra` at `/etc/perses/extra`, because the team keeps extra files for the server there.

## Your task

In the namespace `perses`:

1. Find every reason the Perses server does not serve, from the resource's status conditions, the operator log and the events.
2. Fix the `Perses` resource so the server runs the image `docker.io/persesdev/perses:v0.54.0`.
3. Keep the volume mount `extra` at `/etc/perses/extra`, backed by the ConfigMap `perses-extra`.

## Constraints

- **Fix the resource in place.** Do not delete the `Perses` resource `perses` and create it again.
- Do not remove the volume mount `extra`.
- Do not edit the Deployment or the Service by hand; change the `Perses` resource.

## Done when

- The `Perses` resource is `Available=True` and `Degraded=False`.
- The Deployment `perses` has a ready replica running `docker.io/persesdev/perses:v0.54.0`.
- `http://perses.perses:8080/api/v1/projects` answers from the `tester` pod in the namespace `observability`.
- The Deployment mounts the volume `extra` from the ConfigMap `perses-extra`.
