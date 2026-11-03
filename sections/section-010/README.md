# Section 010: Running Perses With The Perses Operator

A Perses server can run as a plain Deployment that someone installs once and then forgets. The Perses Operator turns that server into a Kubernetes resource: you declare one `Perses` object, and a controller creates the Deployment, the Service and the configuration, and keeps them as declared. When something is wrong, the answer is in the object's status, not in a pile of hand-made objects.

This section comes first because every later topic sits on top of it. Dashboards and datasources only reach Perses when the operator can find and reach a server. So the first skill is to run a server from a `Perses` resource and to read why it does not run.

**Topic covered:** Running Perses With The Perses Operator

## What you will learn

- What an operator is, and what the Perses Operator does on every reconciliation.
- Installing the operator with its Helm chart, with and without cert-manager.
- The fields of the `Perses` resource: image, configuration, storage, Service, resources, volumes.
- Which workload the operator creates (a Deployment or a StatefulSet) and how it names it.
- How the operator reaches each Perses server, and why renaming the Service breaks it.
- Reading the `Available` and `Degraded` conditions, the operator log and the Kubernetes events.
- Configuring the server: storage and workload kinds, `spec.config`, pod settings and replicas, TLS, provisioning and `spec.client`.
- Installing and upgrading the operator with Helm.

## The learning path

The first module has a landing page, four short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster where you can explore freely.

### 1. Run Perses With The Perses Operator

The playground runs the operator and a Perses server declared as a `Perses` resource named `perses` in the namespace `perses`.

1. What The Perses Operator Does
2. The Perses Resource
3. Status Conditions And Troubleshooting, followed by the lab **Fix A Perses Server That Never Serves**
4. Install And Upgrade The Operator
5. Summary

### 2. Configure The Perses Server

The second module has a landing page, four short parts, a graded lab right after the part it tests, and a summary. Its playground runs the operator and a Perses server with an `emptyDir` database.

1. Persistent Storage And Workload Kinds, followed by the lab **Make Perses Data Survive A Restart**
2. The Server Configuration In spec.config
3. Pod Settings And Replicas
4. TLS, Provisioning And The Operator Client
5. Summary

## Section capstone: Make The Operator Reach Its Perses Server

The capstone is one graded scenario that combines the whole section. A Perses server has been changed in a hurry. The `Perses` resource says `Available`, yet the dashboard in the namespace `payments` never reaches the server, and the server pod keeps restarting. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-111-capstone-010
```
