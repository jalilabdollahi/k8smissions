## Making Service `db` headless

Changing `clusterIP` is not allowed on an existing Service, so people delete and recreate `db`. Even then `db-0.db-hs` still does not resolve, because the Service has the wrong name, and clients lose their cluster IP. The validator checks that `db` keeps one.

## Trying to edit `serviceName`

The field is immutable on a StatefulSet. Deleting the StatefulSet to change it risks the members and anything they store; adding the Service the set already asks for is safe.

## Creating the Service but with another name or no selector

`db-headless` instead of `db-hs` produces no records, and a headless Service without `app=db` as selector has no endpoints, so there is nothing to publish. The name must equal `serviceName` exactly.
