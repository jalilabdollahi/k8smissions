# Common mistakes: level 10

**Testing persistence by restarting the container.** Killing the app process keeps an `emptyDir` intact, so the old setup passes that test. Only deleting the pod proves the data is durable.

**Using `kubectl patch` with a merge patch to add the claim.** Adding `persistentVolumeClaim` to the `uploads` volume keeps the old `emptyDir` beside it, and the API server rejects a volume with more than one source. Replace the volume entry with a JSON patch or edit the Deployment.

**Moving `/scratch` to the claim as well.** It works, but the temporary area is supposed to stay disposable. Putting throw-away files on durable storage is what the check at `/scratch` is there to catch.
