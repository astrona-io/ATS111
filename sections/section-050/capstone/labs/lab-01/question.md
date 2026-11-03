# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Operating Perses

## Scenario

The finance team asked for a reporting server. The platform team created a second Perses server, `reports`, in the namespace `reports`, and finance wrote two dashboards in the namespace `finance`. Three days later, nothing works:

- The server `reports` has never become available.
- The dashboard `weekly` is in the cluster and shows no error, but is not on the server.
- The dashboard `monthly` is refused by the server once it runs.

## Your task

Find the cause of each problem by following the conditions, the events and the logs, and correct it in the objects.

## Constraints

- Do not delete and recreate the `Perses` resource or the dashboards. Change them.
- Do not create dashboards through the Perses API or `percli`.
- Keep `weekly` and `monthly` in the namespace `finance`, and keep the server in `reports`.
- `monthly` must keep the panel reference `#/spec/panels/totals`. Add the panel, do not remove the reference.

## Done when

- The `Perses` resource `reports` is `Available=True` and `Degraded=False`, and runs the image `docker.io/persesdev/perses:v0.54.0`.
- `weekly` and `monthly` are `Available=True`.
- The server `reports` serves both dashboards in the project `finance`.
- The server `perses` in the namespace `perses` has neither dashboard.
