## Raising the value of `payments-high`

The class fields are immutable (the API rejects the edit), and a bigger number would not help anyway: the problem is the policy, not the rank.

## Deleting sandbox pods or scaling `dev-sandbox` down by hand

A freed slot lets the gateway start once, but the Deployment keeps its `Never` policy, and the sandbox controller recreates pods that then compete for the room. The incident returns on the next deploy. The sandbox must stay at 8 replicas.

## Changing the class but not replacing the pods

`preemptionPolicy` is copied into each pod at creation. Pods that already exist keep `Never`; a rollout (or deleting the pending pods) is needed for new ones to get the new policy.
