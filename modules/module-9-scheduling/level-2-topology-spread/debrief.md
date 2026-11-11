## What was broken

`catalog-api` had a spread constraint (`maxSkew: 1` over `kubernetes.io/hostname`, `DoNotSchedule`), but its `labelSelector` was `app: catalog`. The pods are labelled `app.kubernetes.io/name: catalog-api`, so the constraint counted zero matching pods on every node.

## The evidence

All six pods sat on one worker in `kubectl get pods -o wide`, even though the other worker had been schedulable for hours. The constraint looked correct at a glance, and only the comparison between its selector and `kubectl get pods --show-labels` showed the mismatch.

## Why Kubernetes behaves this way

The scheduler never assumes which pods a constraint is about. Skew is computed from the pods that match `labelSelector` in each topology domain. With no match every domain has 0, the skew is 0 everywhere, and every node is equally good, so the pods followed the cordon history. And because the rule is evaluated only when a pod is scheduled, nothing moves existing pods afterwards.

## The fix

Make the selector match the Deployment's own pod labels. The selector sits in the pod template, so editing it starts a rollout, and the new pods are placed with correct counts. Had the constraint lived anywhere else, a `kubectl rollout restart` would have been needed.

## In production

`matchLabelKeys: [pod-template-hash]`, which this Deployment already had, makes each ReplicaSet count only its own pods during a rollout; without it, the old pods skew the counts and a rolling update can end up lopsided. `DoNotSchedule` makes the spread a hard rule (`ScheduleAnyway` is only a score), and `nodeTaintsPolicy: Honor` stops tainted control-plane nodes from counting as empty domains.

## Commands worth remembering

- `kubectl get pods -o wide --show-labels`
- `kubectl explain pod.spec.topologySpreadConstraints`
- `kubectl rollout restart deploy/<name>`
