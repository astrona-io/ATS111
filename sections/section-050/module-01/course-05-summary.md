# Summary

A Perses platform works only as long as someone can see its state, restore its data, change it without an outage and find the cause when it stops. This module gave you a routine for each.

## What you learned

State is reported in three places. Conditions on the `Perses`, `PersesDashboard` and `PersesDatasource` objects are the operator's own summary. Events in the namespaces show what controllers and the kubelet did and are kept for a short time. Logs of the server and of the operator show requests and reconciles. The server may expose metrics at `/metrics`, depending on its version.

Data that has no source in a custom resource or in Git lives only in the server database. Projects, dashboards and datasources created through the user interface or the API are exported through the API, kept outside the pod, and restored project first. Objects owned by the operator are not restored from a file. A backup is only known to work once it has been restored.

A change goes through the `Perses` resource, because the operator reconciles the Deployment from it. A rollback is a change to that resource or a revert in Git. A rolling update keeps the old pod serving while a new pod fails to start. An upgrade backs up first, upgrades the definitions, then the operator, then one non-production server, then the rest.

Troubleshooting follows the path of a request: the conditions of the object, the events and log of the server, the log of the operator. A selector that matches no server reports no error, so check it against the labels of the servers. The key facts to remember are these:

- Read the conditions before the logs.
- Data created in the user interface needs a backup.
- Change the `Perses` resource, not the Deployment.
- Upgrade the definitions before the operator.
- A restored backup is the only tested backup.

<!-- astrona:playground:destroy -->
