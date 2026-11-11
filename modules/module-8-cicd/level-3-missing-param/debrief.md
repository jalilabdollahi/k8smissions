## What was broken

Pipeline `deploy-notify` takes two params: `env`, a string with no default, and `targets`, an array of channels. The release tool created `notify-prod-9` with only `targets`, and passed it as one string `"slack-payments,pager-oncall,email-finance"`. The run was marked Failed during validation, before any pod existed.

## The evidence

The condition message of the PipelineRun names the problem. First it reported the param `env` that has no value and no default; after that was supplied, it reported that `targets` was given as a string where the Pipeline declares an array. The Pipeline YAML showed both declarations (`type: array` and no `default` on `env`).

## Why Tekton behaved this way

Tekton validates the run against the Pipeline when it reconciles it, in layers: first that every param without a default has a value, then that each value has the declared type. A string is not a one-element array, and a comma-separated string is not three elements, so the second check can only fail after the first passes. The array arrives in the step through `args: ["$(params.targets[*])"]`, which expands to one argument per item; array params cannot be used inside a `script` directly.

## The fix

A new run with `env: prod` and `targets` as a list. Giving `env` a default in the Pipeline is also fine when most runs target one environment, but a default for production is risky: forgetting the param then deploys to prod.

## In production

Prefer required params without defaults for anything dangerous, and defaults for harmless knobs. Validation failures cost no cluster resources, which is why they are cheap to hit and fix.

## Commands worth remembering

- `kubectl explain pipeline.spec.params`
- `kubectl get pipelinerun <name> -o jsonpath='{.status.conditions[0].message}'`
- `kubectl create -f run.yaml` (new name every time via `generateName`)
