# Preview And Change Safely

A change to a `PersesDashboard` or a `PersesDatasource` reaches users within a minute, so the time to find a mistake is before the apply. This part shows two commands that preview a change, where the Kubernetes API server and the Perses server each do their own validation, and how a deletion looks while it is in progress.

## Two validations, two places

An object passes two checks on its way to a user. The first check happens when you apply it. The Kubernetes API server checks the object against the schema of its custom resource definition: field names, types and required fields. A misspelled field, or a string where a number belongs, fails here, and the object is not stored.

The second check happens later, when the operator sends the object to a Perses server. The server validates the Perses part, which is everything under `spec.config`: that the plugin kind exists, that its spec is valid and that the layouts refer to existing panels. A failure here does not stop the apply. The object is stored, and its condition says `ValidationFailed`. A preview must show you both kinds of failure, so you need to know which command can see which.

## Preview with the API server

A server-side dry run sends the object through the API server's full validation and admission, and does not store it. Use it for the first check. Save this as `persesdashboard-bad-field.yaml`, with a field name that is not in the schema:

<!-- astrona:playground:renew -->

```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: typo
  namespace: payments
spec:
  instanceSelctor:
    matchLabels:
      app.kubernetes.io/instance: perses
  config:
    display:
      name: Typo
    duration: 1h
    panels: {}
    layouts: []
```

Run the dry run:

```sh
kubectl apply --dry-run=server -f persesdashboard-bad-field.yaml
```

The command fails with an error that names the unknown field `instanceSelctor`, depending on the strictness of the cluster's field validation. Run it again with `--validate=strict` to make sure unknown fields are an error, and confirm that nothing was stored:

```sh
kubectl apply --dry-run=server --validate=strict -f persesdashboard-bad-field.yaml
kubectl -n payments get persesdashboard typo
```

The second command answers that the object is not found. The dry run catches a wrong field in the Kubernetes part of the object. It does not catch a layout that refers to a missing panel, because the schema accepts any text there.

## See what an apply would change

`kubectl diff` compares the file with the live object and prints the difference without changing anything. After an object exists, edit the file and run the diff before the apply. Change the display name in `persesdashboard-payments-jobs.yaml` and run:

```sh
kubectl diff -f persesdashboard-payments-jobs.yaml
```

The output is a unified diff of the object, with the changed display name and the fields that Kubernetes updates itself, such as the generation. No output and exit code `0` mean there is no difference. In a pipeline, the diff is the step a reviewer reads before approving the change.

## Find Perses-level errors early

The Perses part of an object is only validated by a Perses server. The safe way to get that check without risk is to send the object to a server that is not production first. A staging server selected by a label, as in the earlier part of this module, accepts the dashboard and reports `ValidationFailed` on the object if the Perses server refuses it. Read the condition, fix the object, and only then widen the selector.

## Deletion in progress

Deleting a custom resource is an API request, and the object can stay visible for a short time if something holds it, for example a finalizer. A finalizer is a name in `metadata.finalizers` that tells the API server to wait until a controller has finished cleanup work before it removes the object. If an object is deleted and does not disappear, look at its metadata:

```sh
kubectl -n payments get persesdashboard jobs -o jsonpath='{.metadata.deletionTimestamp}{" "}{.metadata.finalizers}{"\n"}'
```

An empty `deletionTimestamp` means no deletion is requested. A timestamp with a finalizer means the controller has not finished. The usual cause is that the operator cannot reach the server to delete the copy there, so read the operator log and the conditions of the `Perses` resource before you remove the finalizer by hand. Removing a finalizer skips the cleanup and can leave the dashboard on the server.

## Keep a copy before a risky change

The objects are small and cheap to save. Before a change you are not sure about, write the live objects to a file:

```sh
kubectl -n payments get persesdashboards,persesdatasources -o yaml > payments-backup.yaml
```

If the change goes wrong, applying the saved file restores the objects. The file contains fields such as `resourceVersion` and `status` that the API server sets, so remove them or apply with care. A repository is the better backup, which is the subject of delivering objects with Flux.

You can now preview a change with a dry run and a diff, name the two validations an object passes, and read the metadata of an object that does not delete. That completes the picture of how a team's resources are routed and shaped.

## Common pitfalls

> [!WARNING]
> - **Trusting a dry run for the Perses part of the object.** The dry run checks the schema only. A server checks the panels and the layouts.
> - **Removing a finalizer to make a delete finish.** The cleanup on the server is skipped.
> - **Applying a saved `get -o yaml` file as it is.** It contains server-set fields. Remove `status`, `resourceVersion` and `uid` first.
> - **Skipping staging.** The first Perses server that sees an object should not be the one users read.
