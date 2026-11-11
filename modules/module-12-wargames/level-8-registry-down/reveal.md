Three faults, each hidden behind the previous one:

1. **App image on the dead host.** `registry.corp-mirror.invalid/shop/http-echo:1.0` can never resolve; the same image is `hashicorp/http-echo:1.0` on Docker Hub. Do not swap the app for another image: the page body (`storefront 3.2 - spring catalogue`) identifies the right one.
2. **Init container `schema-check` on the dead host** (`registry.corp-mirror.invalid/tools/busybox:1.36` -> `busybox:1.36`). Init containers run before the app, so this shows up first as `Init:ImagePullBackOff`.
3. **`metrics-sidecar` has `imagePullPolicy: Never`** for `busybox:1.34.1`, which is not on the nodes, so it fails with `ErrImageNeverPull`. Set the policy to `IfNotPresent` (or remove it) so the node pulls the image.

`kubectl set image deploy/storefront storefront=hashicorp/http-echo:1.0 schema-check=busybox:1.36`, then patch the sidecar's pull policy.
