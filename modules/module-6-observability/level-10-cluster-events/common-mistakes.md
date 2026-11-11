## Debugging only the failing app

Logs and events in `k8smissions` describe the symptom: the app cannot reach its cache. Restarting it or reading its code leads nowhere. Follow the dependency and look at events in its namespace, or at all namespaces at once.

## Creating the Secret with the wrong key or value

The volume exposes each key as a file, and the cache reads `password`. A Secret with another key name mounts fine but the server cannot read the file; a Secret with a made-up password mounts fine too, and then the app's log says `invalid password` instead of `PONG ok`. Copy the value the app already holds.

## Creating the Secret in the app's namespace

`cache-auth` in `k8smissions` is invisible to a pod in `cache-tier`. The cache pod stays in ContainerCreating and the validator rejects the stray copy.
