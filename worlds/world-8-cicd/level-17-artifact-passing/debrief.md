# Lost Artifact

## What Was Broken
The Pipeline referenced $(tasks.build.results.image-digest) but the build-task declared its result as 'imageDigest' (camelCase). The hyphen vs camelCase mismatch caused the deploy Task to receive an empty string.

## The Fix
Use the exact case-sensitive result name as declared in the Task's spec.results.

## Why It Matters
Tekton results are the primary mechanism for inter-task data passing. They're stored as files in /tekton/results/ inside the step container. The Pipeline resolves variable expressions at runtime.

## Pro Tip
List a Task's result declarations: kubectl get task <name> -o jsonpath='{.spec.results[*].name}'. Use these exact names in Pipeline variable expressions.

## Concepts
Tekton, results, variable expressions, inter-task data, case sensitivity
