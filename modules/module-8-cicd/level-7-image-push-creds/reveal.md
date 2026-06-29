## What went wrong

Pushing an image to a private registry requires authentication. Tekton looks for `dockerconfigjson` type secrets attached to the TaskRun's ServiceAccount. With no secrets attached, the push step has no credentials and gets 401 Unauthorized.

## Fix

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-sa
  namespace: k8smissions
imagePullSecrets:
- name: registry-creds
secrets:
- name: registry-creds
```

The `registry-creds` Secret should be of type `kubernetes.io/dockerconfigjson`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-creds
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

## Why this matters

Both `imagePullSecrets` and `secrets` serve different purposes: `imagePullSecrets` is used by Kubernetes to pull images *for* the ServiceAccount's pods; `secrets` is mounted into the pod and used by tools (like `docker push` or `crane`) running *inside* the pod to push images *from* the step. For a CI image build-and-push step, you need both — the step container image must be pullable, and the step itself must be able to push the built image.