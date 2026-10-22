# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Running Perses With The Perses Operator

## Scenario

The platform team changed the `Perses` resource `perses` in the namespace `perses` in a hurry. They gave the Service a "nicer" name and lowered the memory to save money. The `Perses` resource still says `Available`. Since then, the `payments` team's dashboard and datasource never appear in Perses, and the Perses pod keeps restarting.

## Your task

1. Find out why the `PersesDashboard` and the `PersesDatasource` in the namespace `payments` do not reach the Perses server. Read their status conditions.
2. Find out why the Perses pod keeps restarting.
3. Fix the `Perses` resource so the server runs steadily and the operator can reach it, then make sure the `payments` resources reach Perses.

## Constraints

- **Fix the `Perses` resource in place.** Do not delete it and create it again, and do not rename it: other teams use `http://perses.perses:8080`.
- Give the server at least `128Mi` of memory.
- Do not create the dashboard or the datasource through the Perses API or `percli`; they must come from the custom resources in `payments`.

## Done when

- The Service `perses` in the namespace `perses` has a ready Perses pod behind it, and `http://perses.perses:8080` answers.
- The Perses pod is ready and not in `CrashLoopBackOff`, with a memory limit of at least `128Mi`.
- The `PersesDatasource` `prometheus` and the `PersesDashboard` `payments-overview` in `payments` are `Available`, and the Perses API serves the dashboard `payments-overview` in the project `payments` with the name `Payments Overview`.
