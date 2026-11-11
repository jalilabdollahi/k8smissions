## What was broken

Service `hook` is a small receiver that stands in for Tekton Triggers. It reads `binding.json`, maps fields of a push payload to PipelineRun params and creates the run through the API with its own ServiceAccount. The `revision` param pointed at `body.head_commit.sha`. A push payload has no such key (the commit SHA is `head_commit.id`), so every run was created with an empty revision and the `clone` Task stopped at its first check.

## The evidence

The receiver logged `binding: body.head_commit.sha not found in payload, param revision left empty` for each delivery, and `kubectl get pipelinerun push-8f21 -o jsonpath='{.spec.params}'` showed `revision` as an empty string. Nothing was wrong with the Pipeline, the Git server or RBAC: the run was created, so the receiver could talk to the API.

## Why it behaved this way

The mapping is plain data in a ConfigMap, and the receiver reads it once when the process starts. Kubernetes does refresh a ConfigMap volume after a while, but the file is not what the program uses; its in-memory copy is. Editing the ConfigMap therefore changes nothing until the pod restarts, so a correct edit looks like a failed fix.

## The fix

Set the path to `body.head_commit.id` and restart the Deployment so the new mapping is loaded.

## In production

Tekton Triggers does this with TriggerBindings and an EventListener that validates the webhook secret; the field-path mistakes are identical. Always log what a binding could not resolve, and prefer failing the delivery over creating a run with empty params.

## Commands worth remembering

- `kubectl logs deploy/hook --tail=20`
- `kubectl get pipelinerun -l source=webhook -o custom-columns=NAME:.metadata.name,REV:.spec.params[0].value`
- `kubectl rollout restart deployment/hook`
