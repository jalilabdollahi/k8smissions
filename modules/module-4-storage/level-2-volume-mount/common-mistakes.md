# Common mistakes: level 2

**Recreating or resizing the PVC.** The claim is fine: it is Bound and mounted. A new claim mounted at the same wrong path would lose uploads in exactly the same way. Look at the paths, not the claim.

**Testing with a container crash instead of a pod replacement.** Checking only that the app still answers after a restart proves nothing; deleting the pod is the real test. After changing anything, upload a file, run `kubectl delete pod`, and download it again.

**Changing the Service, probes or replicas.** The app answers requests correctly, so the networking side is not the issue. Changing `replicas` also makes things worse: with a ReadWriteOnce claim extra replicas may be unable to mount it.
