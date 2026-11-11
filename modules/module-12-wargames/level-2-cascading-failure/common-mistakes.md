**Restarting or scaling `gateway`.** It looks like the culprit because it is the thing returning 504, but its pods are NotReady only because `auth` is unavailable. More replicas of a pod that fails its readiness check are more NotReady pods. Trace the dependency chain downward first.

**Fixing `auth` and declaring victory.** `gateway` turns Ready and the 503 becomes a 504 with a different message. That is the next fault, in `users-cache`, not a regression: read the message in the response and the `auth` log.

**Recreating the Secret with a made-up value under the right key.** The app starts, but tokens are signed with a different key than the one other components may rely on. Copy the value that is already stored under `JWT_SECRET` (or point the app at that file) rather than inventing a new one.
