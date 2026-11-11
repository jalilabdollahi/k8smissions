**Stopping when the Application turns Healthy.** The fix is judged from the user's side: with a wrong `targetPort` the Service has endpoints and Argo reports Healthy while every request is refused. Test through the Service from the `probe` pod.

**Setting `ignoreMissingValueFiles: true` to make the error go away.** The error disappears and Helm renders the dev defaults: one replica, the dev message and the old image tag. The production page is still wrong.

**Giving the pods generous requests.** The quota allows 300m CPU and 256Mi of memory for the whole namespace. Two replicas at 200m each leave the second pod rejected. Read the quota with `kubectl describe resourcequota` and size the requests to it.

**Patching the live Deployment or Service.** Automated sync with self-heal puts the Git or Helm state back within seconds. The values have to change where Argo reads them.
