**`helm rollback ledger-api 1`.** It restores 3 replicas and the production message, but it also restores image tag `0.2.3`, so the release is healthy and the objective (tag 1.0) is not met. Rollback undoes the build CI wanted to ship. Upgrade with the recovered values and the new tag instead.

**`helm upgrade --reuse-values --set image.tag=1.0`.** `--reuse-values` reuses the values of the *last* revision, which is the broken one: it only held the tag. You get the same dev defaults again. The values you need are in revision 1, so read them from there.

**Passing only the values that look wrong.** Fixing just the replica count or the message by `--set` leaves the image repository at its dev default and the pod in ImagePullBackOff. Compare the full output of `helm get values --all` for both revisions before choosing.
