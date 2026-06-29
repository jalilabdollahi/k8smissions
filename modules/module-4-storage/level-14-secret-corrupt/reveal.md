## What went wrong

Someone ran `echo 'supersecret-api-token-12345' | base64 | base64` (encoding twice) and pasted the result into the Secret's `data` field. The Secret stores double-encoded base64. When injected into the container, Kubernetes decodes it once — leaving behind the inner base64 string, not the real token.

## Fix

In manifest.yaml, replace the token value with a single base64 encoding:

```yaml
data:
  token: c3VwZXJzZWNyZXQtYXBpLXRva2VuLTEyMzQ1
```

Or use `stringData` to avoid manual encoding entirely:

```yaml
stringData:
  token: supersecret-api-token-12345
```

## Why stringData is safer

With `stringData`, you write the plain value and Kubernetes base64-encodes it for storage. No manual encoding, no double-encoding risk. The `data` field requires you to encode manually — one extra `| base64` in your pipeline corrupts the value.