## What was broken

`ticket-viewer` is an aggregated ClusterRole: its `rules` are generated from every ClusterRole labelled `aggregate-to-ticket-viewer: "true"`. Two of the roles that should have fed it had wrong labels, one with a typo in the value (`ture`), one with a different key. Only `ticket-notes` was labelled correctly, so support got almost nothing, and the hand-written rules on `ticket-viewer` were erased each time the controller reconciled.

## Evidence

`get clusterrole ticket-viewer -o yaml` shows an `aggregationRule` next to rules that do not contain what someone had added. `get clusterrole --show-labels` lists the labels side by side. `kubectl auth can-i ... --as=x --as-group=support` gives the effective answer without a real user.

## Why Kubernetes behaved this way

The ClusterRole aggregation controller in kube-controller-manager owns `rules` of any role that has an `aggregationRule`. It evaluates the label selectors, merges the rules of the matching roles and writes the result back, so every manual change is reverted. Selectors match label key and value exactly: `ture` and `rbac.shop.example/aggregate-to-ticket-viewer` match nothing, and no error is produced. This is how `admin`, `edit` and `view` pick up rules from CRDs.

## The fix

Label the two contributors with exactly `aggregate-to-ticket-viewer=true`. The controller merges their rules within seconds, and `ticket-viewer` keeps its aggregation. The wrong labels left on the roles do nothing and can be removed.

## In production

Put the permission in the small role that owns the resource and let aggregation compose the big roles. Review aggregated roles by their output (`kubectl get clusterrole <name> -o yaml`), and keep the selector label in a team convention so typos are caught in code review.

## Commands worth remembering

- `kubectl get clusterrole -l aggregate-to-ticket-viewer=true`
- `kubectl auth can-i --list --as=x --as-group=support -n <ns>`
- `kubectl label clusterrole <name> <key>=<value> --overwrite`
