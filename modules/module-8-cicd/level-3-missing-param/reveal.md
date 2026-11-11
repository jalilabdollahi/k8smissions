The Pipeline declares `env` (string, no default) and `targets` (array). The run supplied only `targets`, and as a single comma-separated string.

1. `kubectl get pipelinerun notify-prod-9 -o jsonpath='{.status.conditions[0].message}'` names the missing param `env`; once that is supplied, the type mismatch for `targets` shows up.
2. Create a new PipelineRun of `deploy-notify` with `env: prod` and `targets` as a list of `slack-payments`, `pager-oncall`, `email-finance`.
3. (Alternative for `env`: add `default: prod` to the Pipeline param.)
4. The `send` step logs `env=prod` and three `notified` lines.
