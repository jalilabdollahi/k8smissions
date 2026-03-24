# Missing Parameter

## What Was Broken
The Task declared param IMAGE with no default value, making it required. The TaskRun provided no params, causing validation failure before any step ran.

## The Fix
Supply all required params in the TaskRun.spec.params list.

## Why It Matters
Tekton validates params at admission time. Params with 'default:' are optional; those without are required. Always check Task param definitions before creating TaskRuns.

## Pro Tip
Use 'kubectl get task <name> -o jsonpath='{.spec.params[*]}'' to see all params and their defaults.

## Concepts
Tekton, params, required parameter, validation, TaskRun
