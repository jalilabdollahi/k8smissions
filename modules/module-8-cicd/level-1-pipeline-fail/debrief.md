## What was broken

Task `build` has two steps. `generate` computes the version (`2.9.42`) and writes it to `/tmp/version.txt`; `publish` is meant to read that file. It could not, and exited 1 with "No such file or directory". The Task also declares a result `version` that nothing ever wrote.

## The evidence

`kubectl get taskrun` showed `build` failed, `kubectl logs <pod> -c step-generate` showed the file being written, and `-c step-publish` showed it missing a moment later. Two steps, same pod, one succeeded and the next could not see its output: the filesystems are not shared.

## Why Tekton behaved this way

Each step is a separate container of one pod. They share the pod's network and the volumes Tekton mounts (workspaces, `/workspace`, `/tekton/results`, `/tekton/home`), but each has its own root filesystem, so `/tmp` is private to a step. The supported way to hand a value to later steps, and out of the Task, is a result: declare it under `spec.results` and write to `$(results.NAME.path)`. Re-running the pipeline cannot help, because the definition is the bug.

## The fix

Write the version to `$(results.version.path)` in `generate`, read it from there in `publish`, and start a new run. The result is then also visible to a Pipeline as `$(tasks.build.results.version)`.

## In production

Results are limited to a few kilobytes (4 KB per Task), so they carry versions and digests, not files; big artifacts go through a workspace. Keep one thing per step so a failure points at one container.

## Commands worth remembering

- `kubectl get taskrun <name> -o jsonpath='{.status.results}'`
- `kubectl logs <pod> -c step-<name>`
- `kubectl get taskrun <name> -o jsonpath='{.status.steps[*].terminated.exitCode}'`
