## What was broken

Secret `registry-creds` is a valid `kubernetes.io/dockerconfigjson` Secret, bound to ServiceAccount `builder`, and the `push` step still got 401. Inside the encoded JSON the credentials were stored under the host `registry:5000`, while the step pushes to `registry.k8smissions.svc.cluster.local:5000`. And the `auth` field, base64 of `ci-push:ship-it-4711`, had been produced with `echo`, so it contained a trailing newline: even a matching host would have sent a wrong password.

## The evidence

The step log named the host and the error, `UNAUTHORIZED: authentication required`. Decoding `.dockerconfigjson` and then the `auth` value (`base64 -d | od -c` shows the final `\n`) exposed both defects. `kubectl describe sa builder` and `kubectl get secret` looked perfectly healthy; that is what made this level confusing.

## Why Kubernetes and Tekton behaved this way

Tekton copies the Secret into the step's docker config without judging it. The client, `crane` here, looks up an entry by the exact registry host and port; no entry means an anonymous request, and the registry answers 401 with a token challenge. The registry compares the decoded password byte for byte, so a newline is a different password.

## The fix

Rebuild the Secret with `kubectl create secret docker-registry`, naming the same host the step uses, and run the Pipeline again. The registry itself needed no change, and anonymous pushes must stay refused.

## In production

Create credentials with the tool, not by hand-encoding: `echo -n` or `printf` if you must. Use one canonical registry host name everywhere, so the config and the image references cannot drift. Prefer short-lived robot tokens over long-lived passwords.

## Commands worth remembering

- `kubectl get secret NAME -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d`
- `kubectl create secret docker-registry NAME --docker-server=... --dry-run=client -o yaml`
- `curl -u user:pass http://registry:5000/v2/<repo>/tags/list`
