## What went wrong

Tekton git-clone uses the ServiceAccount's attached secrets to find SSH credentials. The ServiceAccount has no secrets, so there are no credentials to present to the remote Git server. The clone fails with an authentication error.

## Fix

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pipeline-sa
  namespace: k8smissions
secrets:
- name: git-ssh-key
```

The `git-ssh-key` Secret should be of type `kubernetes.io/ssh-auth`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: git-ssh-key
  annotations:
    tekton.dev/git-0: github.com
type: kubernetes.io/ssh-auth
data:
  ssh-privatekey: <base64-encoded-private-key>
```

## Why this matters

Tekton's credential system works through ServiceAccount secret attachments. The `tekton.dev/git-0: github.com` annotation tells Tekton which host this credential applies to. On the pod, Tekton mounts and configures the SSH key automatically — you don't write git config manually in your script. This same pattern applies to registry credentials (`kubernetes.io/dockerconfigjson`) for image push/pull operations.