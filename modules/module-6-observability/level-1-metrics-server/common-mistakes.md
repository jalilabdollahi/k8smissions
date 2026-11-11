## Reinstalling or restarting metrics-server

`kubectl top` already works, so the server is healthy. Touching it only risks breaking every other consumer of the Metrics API. When one client fails and another succeeds, the difference lies in the client.

## Editing the ConfigMap and waiting

The pod mounts the ConfigMap, and the file on disk does update, but the Python loop never re-reads it. Without a restart the log keeps printing the 404 and you may conclude the fix did not work.

## Granting more RBAC

A 403 would call for RBAC; a 404 does not. Widening the Role changes nothing here, and the validator also requires the service account to stay unable to read Secrets.
