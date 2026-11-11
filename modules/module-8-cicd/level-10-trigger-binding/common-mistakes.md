**Editing the ConfigMap and stopping there.** The receiver loads `binding.json` when it starts. The new pod-visible file is ignored until the process restarts, so the next push still produces an empty revision. Restart the Deployment and check the `binding loaded` log line.

**Fixing the symptom in the Pipeline.** Giving `revision` a default such as `main` makes the empty param disappear, but the run then clones the branch tip instead of the pushed commit. The validator pushes an older commit on purpose.

**Hand-creating a run with the right SHA.** `kubectl create` of a PipelineRun proves the Pipeline works, not the webhook. The check posts a payload to the Service and inspects the run the receiver creates.
