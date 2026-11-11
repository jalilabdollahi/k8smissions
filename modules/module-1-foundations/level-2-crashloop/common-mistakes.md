## Common mistakes

- **Running `kubectl logs <pod>` and concluding the app is fine.** With two containers kubectl shows one of them (the first, unless you pass `-c`). The failing container is `edge`.
- **Changing nginx's `listen` to another port only.** That frees port 80 but the Service still targets 80, and the proxy still forwards to 8080 where nothing listens. If you move nginx you must update the Service `targetPort` and the app port too; it is simpler to move the app.
- **Waiting for back-off to clear after a fix.** An existing pod may wait up to five minutes before restarting. A rollout or deleting the pods starts fresh.
- **Deleting the `edge` container.** The pod goes Ready, but the objective needs the proxy in the path.
