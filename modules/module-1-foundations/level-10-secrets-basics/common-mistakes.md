## Common mistakes

- **Looking for logs.** A `CreateContainerConfigError` pod has never run; the evidence is in `describe pod`.
- **Creating a new Secret named `reports-db` with a `password` key and a guessed value.** The pods start, but the database rejects the wrong credential and the Service answers `db: rejected`.
- **Deleting the Secret to recreate it.** The correct credentials are in it. The validator fails if it is gone.
- **Forgetting that the pods need to be replaced.** Editing the Deployment template does that. Editing only the Secret does not change a container that is not running yet, and a stuck pod can take a while to retry.
