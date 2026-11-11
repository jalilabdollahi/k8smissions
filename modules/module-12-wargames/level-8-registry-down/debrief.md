**What was broken.** Release 3.2 of `storefront` referenced images on a registry host that was retired and no longer resolves, in two places (the app and the init container), and a third container had `imagePullPolicy: Never` for an image that nobody ever loaded onto the nodes.

**The evidence.** `describe pod` shows `Failed to pull image ... no such host` with `ErrImagePull`/`ImagePullBackOff` for the init container first (`Init:ImagePullBackOff` in `get pods`), then for the app once the init container is fixed, and finally `ErrImageNeverPull` / `Container image ... is not present with pull policy of Never` for the sidecar. The old pods were fine because their containers had already started with images that were already pulled.

**Why Kubernetes behaved this way.** The kubelet pulls images when a container starts, according to `imagePullPolicy`: `Always` contacts the registry every time (so even a container restart needs it), `IfNotPresent` uses a local copy when there is one, and `Never` never pulls and fails if the image is not on the node. Init containers run to completion, in order, before the app containers start, so their failures hide everything after them. A rolling update with `maxUnavailable: 0` keeps the old pods serving while the new ones fail, which is why the site stayed up.

**The fix.** Point both references at the public images (same names and tags) and give the sidecar a pull policy that allows pulling. Swapping the app for a different image would have made pods Ready with the wrong page.

**In production.** Keep a pull-through cache or a registry alias you control, pin images by digest, set `imagePullPolicy: IfNotPresent` for tagged immutable images, and watch for `ErrImagePull` in alerts.

**Commands to remember.** `kubectl describe pod`, `kubectl get deploy -o jsonpath='{.spec.template.spec..image}'`, `kubectl set image`.
