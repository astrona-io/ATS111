# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Back Up And Restore Perses Data

## Scenario

The records team keeps two projects on the Perses server `perses`, created through its API, with no custom resources behind them. The project `ledger` was lost when someone deleted it by mistake. A backup of its dashboards, taken last week, is in the ConfigMap `ledger-backup` in the namespace `backups`, under the key `dashboards.json`. The project `notes` still exists and has one dashboard, but nobody has a backup of it.

## Your task

1. Restore the project `ledger` and its dashboards from the ConfigMap `ledger-backup` to the server `perses`.
2. Back up the dashboards of the project `notes`: create a ConfigMap `notes-backup` in the namespace `backups`, with the key `dashboards.json` holding the JSON list that the API returns for the project's dashboards.

## Constraints

- Restore through the Perses API. Do not create custom resources for these dashboards.
- Do not change the ConfigMap `ledger-backup`.
- Do not delete the project `notes`.

## Done when

- The project `ledger` exists and has the dashboard `daily` with the display name `Daily Ledger` and the duration `1h`.
- The ConfigMap `notes-backup` exists and its list holds the dashboard `todo`.
- The ConfigMap `ledger-backup` still holds its original list, and `notes` still exists.
