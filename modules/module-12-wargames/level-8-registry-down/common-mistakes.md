**Swapping the app image for something that is "known to work".** Pods become Ready quickly, but the page body is the wrong one: the validator compares the 3.2 page, which only this application image serves. Change the host, not the application.

**Fixing the main container and expecting the rollout to finish.** The init container runs first and uses the same dead host; and after that the sidecar still has `imagePullPolicy: Never`. Look at the events of the new pod after every change, for every container.

**Only changing `imagePullPolicy` to `IfNotPresent` on the dead-host images.** The policy only says when to pull, not where from: the host still does not resolve, so the pull fails whatever the policy says. The policy matters for the sidecar, whose image is on Docker Hub.
