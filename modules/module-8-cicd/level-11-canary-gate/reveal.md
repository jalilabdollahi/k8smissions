Two independent defects, both in Pipeline `release-checkout`:

1. The canary pod template is labelled `app: checkout-canary`, so Service `checkout` (selector `app: checkout`) never routes to it. The gate sees only stable answers and keeps waiting for 20 canary samples. Label the canary pods `app: checkout` (keeping `track: canary` and the `canary: <name>` label) and use the same labels in its Deployment `selector`; stable has `track: stable`, so the two Deployments do not adopt each other's pods.
2. `canary-gate` has no `timeout`. With a canary that never becomes ready the loop never ends. Add `timeout: 45s` to the `canary-gate` PipelineTask: the task fails, `promote` is skipped and `checkout-stable` is left alone.

Run a new PipelineRun (old ones keep their old spec) with a good version to see `promoted=true`, and with `canary-mode=crash` to see the gate fail.
