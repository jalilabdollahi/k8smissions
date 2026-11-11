## What was broken

Deployment `invoice-mailer` builds its relay address with `SMTP_URL: "http://$(SMTP_HOST):$(SMTP_PORT)/send"`. The two variables it refers to are defined after it in the `env` list. Kubernetes only expands `$(NAME)` for entries listed earlier, so the container received the literal string `http://$(SMTP_HOST):$(SMTP_PORT)/send`, and every request failed to parse.

## The evidence

The pods were healthy, which is why this hid for a day. The logs said it plainly: `calling http://$(SMTP_HOST):$(SMTP_PORT)/send` followed by `send failed`. The names of the host and port were correct, which rules out the Service and the relay.

## Why Kubernetes behaved this way

Environment variables are resolved by the kubelet in list order when the container is created. A reference to a name that is not yet defined is left untouched; it is not an error, because `$(...)` may legitimately be meant for the application. A doubled dollar sign escapes the expansion on purpose.

## The fix

Put the referenced variables first, or write the full URL. It is a change to the pod template, so the Deployment rolls out new pods. Env of a running container cannot change; the container must be replaced.

## In production

Show the effective configuration on startup, as this app did, and prefer simple values over composed ones when order is a worry. `kubectl exec <pod> -- env` shows what the container really received.

## Commands worth remembering

- `kubectl exec <pod> -- env | sort`
- `kubectl get deploy <name> -o jsonpath='{.spec.template.spec.containers[0].env}'`
- `kubectl set env deploy/<name> --list`
