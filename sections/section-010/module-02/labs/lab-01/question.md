# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Configure The Perses Server

## Scenario

The records team keeps the audit projects of their dashboards in a Perses server of their own. The namespace `archive` exists, and nothing runs in it. The team lost its last server's projects when a node was drained, and it does not want that to happen again.

## Your task

In the namespace `archive`:

1. Run a Perses server from a `Perses` resource named `archive` that uses the image `docker.io/persesdev/perses:v0.54.0`, a file database in the folder `/perses` with the extension `yaml`, and a PersistentVolumeClaim of `1Gi`.
2. Give the server container a memory limit of `512Mi`.
3. Create a project named `records` on the server through its API.

## Constraints

- Declare the server with a `Perses` resource. Do not create a Deployment, a StatefulSet or a PersistentVolumeClaim by hand.
- Do not use `emptyDir` for the database.

## Done when

- The `Perses` resource `archive` is `Available=True` and `Degraded=False`.
- The operator created a StatefulSet `archive`, no Deployment `archive`, and a bound PersistentVolumeClaim that requests `1Gi`.
- The container has a memory limit of `512Mi`.
- The project `records` is on the server, and it is still there after the pod `archive-0` is deleted and has started again.
