## Leaving the Deployment running

The Deployment's pods carry `app=ledger-db`, so Service `ledger-db` keeps routing to nameless pods next to the real members. Delete the Deployment once the StatefulSet exists, or before.

## Setting `serviceName` to something else

`serviceName` has to name the headless Service that exists. With a different name, the pods are named correctly but `ledger-db-1.ledger-db` does not resolve, which is the whole point of the migration.

## Scaling the Deployment or renaming pods by hand

Scaling gives more random names, and pods cannot be renamed. Only a controller that assigns ordinals produces `ledger-db-0..2`.
