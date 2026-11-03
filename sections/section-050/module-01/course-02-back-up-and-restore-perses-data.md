# Back Up And Restore Perses Data

Dashboards and datasources that are delivered from Git or from custom resources can be rebuilt: the objects are the source, and the operator copies them again. Data that was created in the Perses user interface or through its API has no such source. It lives in the server database only. A server on `emptyDir` loses it with the pod, and a server on a volume loses it with the volume. This part exports a project through the API and restores it onto an empty server.

## What needs a backup

Sort the data by where its source is:

| Data | Source | Backup needed |
| --- | --- | --- |
| Dashboards and datasources from custom resources | The objects, or Git | No, but keep the objects in Git |
| The `Perses` resource and its configuration | The object, or Git | No |
| Projects, dashboards, variables and datasources created in the user interface or through the API | The server database only | Yes |
| Users and roles of Perses authentication | The server database | Yes |

Objects that came from a custom resource are written back by the operator, so restoring them from a file is not needed and can conflict with the operator. Restore only what the operator does not own.

## Create data that only the server has

Make a project and a dashboard through the API from the tester pod. They do not come from any custom resource:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"kind":"Project","metadata":{"name":"notes"},"spec":{}}' \
  http://perses.perses:8080/api/v1/projects
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"kind":"Dashboard","metadata":{"name":"todo","project":"notes"},"spec":{"display":{"name":"Todo"},"duration":"1h","panels":{},"layouts":[]}}' \
  http://perses.perses:8080/api/v1/projects/notes/dashboards
```

Both calls print the created object. List the dashboards of the project to confirm:

```sh
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/notes/dashboards | jq -r ".[].metadata.name"'
```

## Export a project

The API returns every dashboard of a project as a JSON list. Save it to a file on your machine, and keep it as a ConfigMap in a namespace for backups:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://perses.perses:8080/api/v1/projects/notes/dashboards > notes-dashboards.json
kubectl create namespace backups
kubectl -n backups create configmap notes-backup --from-file=dashboards.json=notes-dashboards.json
```

The same pattern works for datasources of the project at `/api/v1/projects/notes/datasources`, and for the project object itself at `/api/v1/projects/notes`. A ConfigMap holds up to about one megabyte, which is enough for a handful of dashboards. A larger export goes to object storage or to a volume, and the principle stays the same.

The Perses command line `percli` can export and import resources as well. Run `percli --help` and `percli get --help` for the commands of the version you have. The API is used here because it needs no login step in the playground.

## Lose it and restore it

Simulate a loss. Delete the project and check that it is gone:

```sh
kubectl -n observability exec deploy/tester -- curl -s -X DELETE \
  http://perses.perses:8080/api/v1/projects/notes
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects | jq -r ".[].metadata.name"'
```

The project `notes` is not in the list. Restore it from the ConfigMap. The project comes first, because a dashboard needs its project:

```sh
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"kind":"Project","metadata":{"name":"notes"},"spec":{}}' \
  http://perses.perses:8080/api/v1/projects
kubectl -n backups get configmap notes-backup -o jsonpath='{.data.dashboards\.json}' \
  | kubectl -n observability exec -i deploy/tester -- sh -c \
  'jq -c ".[]" | while read -r d; do curl -s -X POST -H "Content-Type: application/json" -d "$d" http://perses.perses:8080/api/v1/projects/notes/dashboards; done'
```

List the dashboards again. `todo` is back. If the server refuses an object because it carries fields that the server sets itself, remove the fields `createdAt`, `updatedAt` and `version` from the metadata with `jq` and try again.

## Test the backup

A backup that was never restored is a guess. Restore onto an empty server on a schedule, not during the incident. A safe way is a second `Perses` resource with a throwaway name, restoring into it, comparing the number of dashboards, and deleting it. If the compare fails, the backup is not usable and you found it while the system was healthy.

## Your mission: Restore A Lost Project From A Backup

You can now sort data by where its source is, export a project, and restore it. The graded lab hands you a server that lost a project and a ConfigMap with its backup, plus a second project that has no backup yet.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-111-playground-050-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-050/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-111-lab-050-01
astrona start ats-111-playground-050-01
```

## Common pitfalls

> [!WARNING]
> - **Backing up objects that the operator owns.** They come back from the cluster. A restore can fight with the operator.
> - **Restoring dashboards before the project.** The server refuses them.
> - **Never testing a restore.** The file may be empty or unusable, and you only learn it in an incident.
> - **Keeping the backup on the same volume as the data.** A lost volume takes both.
