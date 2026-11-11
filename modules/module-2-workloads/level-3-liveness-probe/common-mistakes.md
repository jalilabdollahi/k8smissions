## Removing the liveness probe

The restarts stop, but the app can now hang silently and nothing will ever restart it. The validator requires a probe to be present for that reason.

## Looking for an application bug in the logs

The logs end mid-start with no error, because nothing is wrong with the app. `--previous` plus the Events from `describe` is what shows the container was killed from outside.

## Restarting the Deployment and hoping

`kubectl rollout restart` produces fresh pods with the same probe, which are killed at the same second of their life. A restart cannot help when the timing itself is wrong.
