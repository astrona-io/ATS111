# Summary

A Perses server is configured in four places that live in one `Perses` resource: its storage, its configuration file, its pod and its security. This module showed what each place controls and how to check that the server really uses what you wrote.

## What you learned

The storage setting decides the workload and the fate of the data. `emptyDir` gives a Deployment and loses the database with the pod. Any other storage, for example a `pvcTemplate`, gives a StatefulSet whose pod keeps its name and its PersistentVolumeClaim, so a project survives the deletion of the pod. The proof is always the same: create a project, delete the pod, and read the project again.

The block `spec.config` is the complete Perses configuration file. The operator copies it into a ConfigMap without reading it, so the server, not the operator, refuses a wrong value, and the cause is in the pod log. The server reports what it runs at `/api/config`, which is the check after every change. Secrets do not belong in the block; the configuration has file variants of its keys for that.

The rest of the resource is a pod specification. `kubectl explain` prints every field from the installed CRD. Resources, labels, scheduling and probes work as they do in a pod, and `spec.metadata` labels the pods, not the resource. More replicas of a file database give separate copies of the data, so high availability needs a shared SQL database.

The fields `tls`, `provisioning` and `client` protect and feed the server. TLS encrypts the traffic and needs a certificate for the Service name. Provisioning loads resource files at start. The client field gives the operator the credentials to use when the server requires authentication, and it must be set before authentication is turned on. The key facts to remember are these:

- Persistent data needs a storage setting other than `emptyDir`.
- The server, not the operator, validates `spec.config`.
- Read `/api/config` to see what the server runs.
- A second replica needs a shared database.
- Set `spec.client` before you enable authentication.

<!-- astrona:playground:destroy -->
