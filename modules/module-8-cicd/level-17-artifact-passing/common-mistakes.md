**Fixing the reference name and re-running.** The run is admitted this time, but `deploy` gets an empty digest: nothing ever wrote the result. The error moves from the Pipeline to the Task.

**Passing the tag instead of the digest.** A tag such as the run name resolves in the registry, so a deploy that accepts it would pass, but the objective is that `deploy` receives the digest `build` produced. The Task's guard and the check compare digests.

**Moving the digest file onto a workspace without wiring it.** A file in a workspace only reaches the next Task if the Pipeline declares and binds the workspace for both. A result is the simpler, supported way for a short value.
