## What was broken

A Friday edit changed the image of Deployment `storefront` to `nginx:1.27-alpne`. That tag does not exist in the registry, so the kubelet on each node could not pull the image and the container never started. No container means no Ready pod and no endpoint behind the Service.

## The evidence

`kubectl get pods` showed `ErrImagePull` and `ImagePullBackOff` and `0/1` Ready. `kubectl describe pod` listed the Events: `Failed to pull image "nginx:1.27-alpne": ... not found`. The working sibling `storefront-canary` made the correct tag easy to spot.

## Why Kubernetes behaved this way

`ErrImagePull` is the pull attempt that just failed; `ImagePullBackOff` is the kubelet waiting before the next attempt, with an increasing delay (up to five minutes). They are the same problem at different moments, which is why the status flips between them. The pod stays in `Pending` phase because nothing ever ran.

## The fix

Set the container image to a tag that exists. `kubectl set image` edits the Deployment's pod template, so the Deployment rolls out new pods and the stuck ones disappear.

## In production

The same status appears for private registries without an `imagePullSecret` (message: `pull access denied` or `unauthorized`) and for registry rate limits. Read the event text, it tells you which. Pin tags and let CI check that a tag exists before it edits a manifest.

## Commands worth remembering

- `kubectl describe pod <pod>` (Events)
- `kubectl get deploy -o wide` to compare images
- `kubectl set image deployment/<name> <container>=<image>:<tag>`
