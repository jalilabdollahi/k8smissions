## Binding cluster-admin

It makes the 403s disappear in one command and fails the least-privilege checks: the operator could then read every Secret and delete nodes. Grant what it uses.

## Granting `reports` and expecting the status to work

A rule on `reports` does not include `reports/status`. If the log says it cannot update status, the rule needs the resource written with the subresource.

## Stopping at the first 403

After pods are allowed, the next 403 appears for the ConfigMap and then for the status. Re-read the log (or run `kubectl auth can-i` for each action) until the Reports are Done.
