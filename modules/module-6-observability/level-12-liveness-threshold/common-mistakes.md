## Raising initialDelaySeconds

The restarts are not at start-up; they happen mid-life, on every pause. A longer initial delay delays only the first probe after a restart and changes nothing afterwards.

## Setting an enormous failureThreshold

The restarts stop, but a pod that is really stuck would stay in service for many minutes. The validator caps the window (period times threshold) at 2 minutes.

## Removing the liveness probe

Nothing restarts the pod any more, including when it truly hangs. The probe must stay.
