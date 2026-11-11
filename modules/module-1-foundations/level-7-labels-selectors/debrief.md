## What was broken

Service `blog` selects pods with `app=blog,tier=web`. During a refactor the Deployment's pod template got `tier: frontend` instead, so the pods carried `app=blog` and `tier=frontend`. The Service matched none of them, its endpoints stayed empty, and visits hung or were refused.

## The evidence

Everything about the Deployment was green: 3/3 Ready, no restarts. The mismatch only shows between objects: `kubectl get endpoints blog` listed `<none>`, `kubectl describe service blog` showed the selector, and `kubectl get pods --show-labels` showed the real labels.

## Why Kubernetes behaved this way

A Service never looks at Deployments. The endpoints controller lists pods whose labels satisfy `spec.selector` and are Ready. The Deployment's own selector (`app=blog`) only decides which pods it owns, and it is immutable, while the pod template labels are what new pods are stamped with. Those two sets of labels are independent.

## The fix

Change the label in the pod template to `tier: web`. The Deployment rolls out new pods with the right labels and the Service picks them up as they become Ready. Running `kubectl label pod ... tier=web` would show endpoints at once, but the next pod the Deployment creates would be unlabelled again, which is why the validator replaces a pod.

## In production

Use a shared set of labels (`app.kubernetes.io/name`, `.../component`) in templates, and check `kubectl get endpoints` after any template edit. Selectors that name labels the app does not own break quietly.

## Commands worth remembering

- `kubectl get pods --show-labels -l app=blog`
- `kubectl get endpoints <svc>`
- `kubectl get pods -l tier=web` (test a selector before using it)
