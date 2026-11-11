## Fixing the code and stopping there

After the operator is repaired new deletions are clean, but `ds-legacy-orders` stays: the Datastore is long gone, so no controller will ever look at it again. Check with `kubectl get pods,cm` and delete the leftovers.

## Stripping the finalizer to "unstick" things

Patching `finalizers: null` makes deletions complete, which is how the leak happened in the first place. The finalizer is what gives the operator its chance to clean up.

## Forgetting to restart the operator

The script is read when the pod starts. Editing the ConfigMap changes the file under `/app`, but the running Python process keeps executing the old code until the pod is restarted.
