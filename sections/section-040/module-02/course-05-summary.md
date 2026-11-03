# Summary

Rights per namespace give each team a boundary. This module added the limits that a boundary needs to be safe on a shared server: how many objects, from where, with what settings, and with which identity.

## What you learned

A ResourceQuota with the key `count/persesdashboards.perses.dev` caps the number of dashboards in a namespace, and the same form works for datasources. It applies to every user, it refuses new objects and removes none, and a refused object shows as an `exceeded quota` error to `kubectl` and in the message of a Flux delivery.

A NetworkPolicy in the namespace of the Perses server decides which namespaces may call it. The operator's namespace must be on the list, or delivery stops. A policy only has an effect when the network plugin enforces it, so you test with a pod that should be refused.

The server configuration decides what an API call can change. A read-only server refuses every write, including those of the operator, so it does not belong on a managed server. With authentication on, the operator needs credentials in `spec.client`, found with `kubectl explain`.

The operator has cluster-wide rights from its chart. `kubectl auth can-i --as` shows what they are, and team ServiceAccounts must have none in the operator's namespace. The key facts to remember are these:

- Quotas for custom resources use `count/<resource>.<group>`.
- A policy that blocks the operator stops delivery silently.
- Test a policy with a pod it should refuse.
- Read-only mode and the operator do not work together.
- Print the rules of a role. The name tells little.

<!-- astrona:playground:destroy -->
