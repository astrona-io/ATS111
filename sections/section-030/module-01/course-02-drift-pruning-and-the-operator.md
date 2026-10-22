# Drift, Pruning And The Operator

Git is the desired state, but people still have `kubectl` and a Perses user interface. Drift is any difference between the live state and Git, for example after a hand edit. With two controllers in the chain, drift can happen at two levels, and each level is corrected by a different controller at a different time. This part makes both kinds of drift on purpose, then deletes a dashboard from Git to see pruning remove it everywhere.

## Drift in the cluster: a hand edit of the object

The commands below need three things: the Secret `fleet-auth` with the Gitea credentials in `flux-system`, the `GitRepository` `fleet` for `http://gitea.localtest.me:3000/gitops/fleet.git`, and the Flux `Kustomization` `payments-dashboards`, which applies `./dashboards/payments` from it with `prune: true`. They also need your clone of the repository in the folder `fleet` and the Gitea port-forward running.

Change the dashboard's display name directly on the object, as someone with `kubectl` access would:

<!-- astrona:playground:renew -->

```sh
kubectl -n payments patch persesdashboard payments-overview --type merge \
  -p '{"spec":{"config":{"display":{"name":"Edited by hand"}}}}'
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards/payments-overview | jq -r .spec.display.name'
```

Perses answers `Edited by hand`. The operator did its job: the object changed, so it updated Perses. The object no longer matches Git, though. Kustomize-controller applies the folder with server-side apply on every run, which puts back every field that Git sets. Ask it to run now:

```sh
flux reconcile kustomization payments-dashboards
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://perses.perses:8080/api/v1/projects/payments/dashboards/payments-overview | jq -r .spec.display.name'
```

The name is back to the one in Git, in the object and then in Perses. Drift in the cluster lasts at most until the next run of the Flux `Kustomization`, here five minutes.

## Drift in Perses: an edit in the user interface

The second level is the Perses server itself. Someone opens the dashboard in the Perses user interface, changes the title and saves. The operator does not watch Perses; it only reconciles when its objects change, when it restarts, or at the controller's long periodic resync. And Flux sees no difference, because the object in the cluster still matches Git exactly, so its next run changes nothing and starts no reconciliation.

So an edit made inside Perses stays until something touches the object. Any change to the object counts, including an annotation, which is also how you correct such drift on demand:

```sh
kubectl -n payments annotate persesdashboard payments-overview \
  "astrona.io/retry-at=$(date +%s)" --overwrite
```

The operator reconciles the object, compares it with the Perses copy, finds the difference, and writes the object's version back. If you edited the title in the user interface before running the command, the title is now the one from Git again. The annotation is not in Git, but Flux leaves it alone: server-side apply only manages the fields that Git sets.

| Where the edit happens | Who corrects it | When |
| --- | --- | --- |
| The `PersesDashboard` object | Flux (kustomize-controller) | On the next run of the Flux `Kustomization` |
| The dashboard inside Perses | The Perses Operator | On the next reconciliation of the object, which nothing schedules soon |

## Pruning: delete from Git, gone everywhere

Pruning means deleting objects from the cluster that Flux applied before and that are no longer in Git. Flux keeps a list of everything it applied, the inventory, in the `Kustomization`'s status, and deletes what drops out of it. Remove the payments dashboard from Git:

```sh
cd fleet
git rm dashboards/payments/dashboard-overview.yaml
git commit -m "Retire the payments overview dashboard" && git push
cd ..
flux reconcile kustomization payments-dashboards --with-source
kubectl -n payments get persesdashboards
```

The `PersesDashboard` is gone from `payments`, because kustomize-controller pruned it. The operator saw the object disappear and deleted the dashboard from Perses; the API now answers `404` for it. The datasource, still in Git, stays. Put the file back with `git revert HEAD` and a push if you want the dashboard again.

Pruning only works for objects in the inventory. If a `Kustomization` runs with `prune: false`, Flux still applies the folder but never deletes, and a file removed from Git while pruning is off is dropped from the inventory without being deleted. Turning pruning on later does not find that object again; it stays in the cluster, and in Perses, until someone deletes it by hand.

The same ideas hold for Argo CD, the other common GitOps agent: an `Application` points at a repository path and a destination namespace, its sync with self-heal corrects drift in the cluster, and its prune option deletes objects removed from Git. Neither agent sees an edit made inside Perses; that stays the operator's job.

You can now predict who corrects which drift and when, and what pruning removes. Together with the first chapter, that is a complete pipeline, which is what the graded lab asks you to build.

## Common pitfalls

> [!WARNING]
> - **Expecting Flux to fix an edit made in Perses.** The object still matches Git, so Flux changes nothing. Touch the object, or wait for the operator's resync.
> - **Switching pruning off "for safety".** Dashboards deleted from Git then stay forever, and turning pruning on later does not remove them.
> - **Deleting the dashboard object by hand while it is still in Git.** Flux applies it again on the next run.
> - **Reading only `flux get`.** A ready `Kustomization` proves the object is in the cluster; the object's conditions prove it reached Perses.

## Your mission: Deliver Dashboards From Git With Flux

You can now connect Flux to a dashboards repository, follow a commit into Perses, and explain drift and pruning at both levels. The graded lab gives you the seeded repository and no Flux objects, and asks you to deliver both teams' folders with pruning on, so that a change pushed to Git reaches Perses.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-111-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-111-lab-030-01
astrona start ats-111-playground-030-01
```
