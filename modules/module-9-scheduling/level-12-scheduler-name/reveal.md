1. The trainer pods have `schedulerName: ml-sheduler`; the scheduler's profile is called `ml-scheduler`. No scheduler matches, so nobody emits an event.
2. `schedulerName` is immutable on a pod, so fix the Deployment template and let it roll:
   `kubectl -n k8smissions patch deploy trainer --type=merge -p '{"spec":{"template":{"spec":{"schedulerName":"ml-scheduler"}}}}'`
3. The new pods are placed by `ml-scheduler` with the `MostAllocated` strategy, which packs all four onto one worker. `kubectl get events` shows `Scheduled` from `ml-scheduler`.
