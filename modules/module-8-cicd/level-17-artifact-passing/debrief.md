## What was broken

Pipeline `ship-api` builds and pushes an image in `build-image` and hands its digest to `deploy-image`. The hand-over failed twice. The Pipeline referred to a result called `image-digest` while the Task declared `digest`, and, once the name was right, the push step never wrote the result at all: it saved the digest in a file inside the pod.

## The evidence

`ship-api-0422` ended with a message saying the referenced result could not be resolved, before any pod existed. After the rename, the `deploy` log read `refusing to deploy: no image digest was passed in`, and `kubectl get taskrun` for `build` showed `status.results` empty although the push had succeeded and the registry held the image.

## Why Tekton behaved this way

Results are the contract between Tasks: a Task declares names, the Pipeline resolves `$(tasks.X.results.NAME)` against that declaration, and a value exists only if a step wrote it to the file at `$(results.NAME.path)` (which Tekton reads when the step finishes). Pods are separate: `/workspace` inside one TaskRun's pod is not shared with the next TaskRun unless a Pipeline workspace backs it, and no error says a file was written to the wrong place.

## The fix

Use the declared result name in the Pipeline and write the digest to the result path in the producer. The digest, not the tag, is what `deploy` verifies against the registry.

## In production

Pass digests, never mutable tags, between build and deploy; Tekton Chains and Kyverno-style policies build on the same idea. Results are limited to a few KB, so pass references (a digest, a URL), not files.

## Commands worth remembering

- `kubectl get taskrun NAME -o jsonpath='{.status.results}'`
- `kubectl get pipelinerun NAME -o jsonpath='{.status.conditions[0].message}'`
- `kubectl explain task.spec.results`
