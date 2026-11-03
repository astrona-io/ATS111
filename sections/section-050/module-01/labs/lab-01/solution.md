# Solution: Restore A Lost Project From A Backup

Work the task yourself first. Running `astrona submit -c sections/section-050/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: that the project `ledger` exists, that its dashboard was restored with the right content, that the backup of `notes` exists, and that nothing that should stay was changed.

## Step 1: Look at the backup

```sh
kubectl -n backups get configmap ledger-backup -o jsonpath='{.data.dashboards\.json}' | head -c 400
```

The value is a JSON list with one dashboard, `daily`.

## Step 2: Restore the project, then the dashboards

The project comes first:

```sh
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"kind":"Project","metadata":{"name":"ledger"},"spec":{}}' \
  http://perses.perses:8080/api/v1/projects
```

Send each dashboard of the list to the project:

```sh
kubectl -n backups get configmap ledger-backup -o jsonpath='{.data.dashboards\.json}' \
  | kubectl -n observability exec -i deploy/tester -- sh -c \
  'jq -c ".[]" | while read -r d; do curl -s -X POST -H "Content-Type: application/json" -d "$d" http://perses.perses:8080/api/v1/projects/ledger/dashboards; done'
```

If the server refuses the object because of the fields it sets itself, remove `createdAt`, `updatedAt` and `version` from `metadata` with `jq` in the same pipe and try again.

## Step 3: Back up notes

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://perses.perses:8080/api/v1/projects/notes/dashboards > notes-dashboards.json
kubectl -n backups create configmap notes-backup --from-file=dashboards.json=notes-dashboards.json
```

## Step 4: Check and submit

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/ledger/dashboards | jq -r ".[].spec.display.name"'
astrona submit -c sections/section-050/module-01/labs/lab-01
```

The first command prints `Daily Ledger`.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Creating a `PersesDashboard` for `daily` | The task asks for a restore through the API, and the grader reads the server |
| Posting the dashboard before the project | The server refuses it because the project does not exist |
| Editing `ledger-backup` to fit | The grader requires the original list |

## Common mistakes

- Saving the backup of `notes` from the project list instead of the dashboard list.
- Restoring the whole JSON list as one object. The API takes one dashboard at a time.
- Forgetting the `Content-Type` header. The server then refuses the body.
