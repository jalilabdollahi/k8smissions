## Common mistakes

- **Editing `containerPort` in the Deployment.** It is documentation only. It restarts the pods and changes nothing about routing.
- **Changing the Service `port` instead of `targetPort`.** Clients call port 80; `port` is what they connect to. The wrong half of the pair is being fixed.
- **Suspecting the selector.** The endpoints list is not empty; the Service already finds the pods.
- **Skipping the logs.** Nothing in the manifest gives the real port away; only the container's own output and arguments do.
