## What was broken

Nothing was wrong with the `InvoiceBatch` objects: the CRD simply did not say how kubectl should present them. It had no `categories`, so `kubectl get all` skipped them, no `shortNames`, and no `additionalPrinterColumns`, so the table only had NAME and AGE. During an incident that is the difference between seeing four failed batches at a glance and opening eight objects one by one.

## The evidence

`kubectl api-resources --categories=all` listed Deployments and Services but not `invoicebatches`. `kubectl get crd ... -o jsonpath='{.spec.names}'` showed only kind, plural and singular. `kubectl get invoicebatch -o yaml` showed that the data (`status.state`, `status.progress`) was there all along.

## Why Kubernetes behaved this way

`kubectl get` is driven by discovery: it asks the API server which resources exist, which categories and short names they declare, and, for printing, receives a Table from the server built out of the CRD's `additionalPrinterColumns`. A CRD that declares nothing gets the default NAME and AGE table and is invisible to `all`. Note that `all` is a convention, not "everything": it only contains resources that opted in.

kubectl keeps discovery responses in `~/.kube/cache` for up to ten minutes, so your own terminal can show the old behaviour after the CRD was fixed. The validator uses an empty cache directory to see what a fresh kubectl sees.

## In production

Operators ship these fields in the CRD: a short name, the category `all` only for objects that belong in an incident view, and printer columns for phase, age and the one or two fields on-call needs. `priority: 1` columns only appear with `-o wide`.

## Worth remembering

- `kubectl api-resources --categories=all`
- `kubectl explain crd.spec.names` and `kubectl explain crd.spec.versions.additionalPrinterColumns`
- `kubectl --cache-dir=$(mktemp -d) get all` to bypass a stale discovery cache
