**Only raising maxSurge.** It looks like the knob that matters, and the rollout speeds up, but with `maxUnavailable: 1` and 8-second waves it still needs a dozen waves and misses the time budget.

**Setting maxUnavailable to 100%.** Every old pod is removed at once, the rollout is quick, and the Service is left with almost no capacity until the new pods are ready. The floor of 30 available replicas catches it, and users would see errors.

**Lowering the waits to zero and nothing else.** Each wave is now quick, but serial replacement still means 40 waves; and a `minReadySeconds` of 0 removes the protection against pods that crash right after becoming Ready.
