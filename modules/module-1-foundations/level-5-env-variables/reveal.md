1. The logs show `calling http://$(SMTP_HOST):$(SMTP_PORT)/send`: the variables were never expanded.
2. In the pod's `env` list `SMTP_URL` comes before `SMTP_HOST` and `SMTP_PORT`, and `$(VAR)` only expands to earlier entries.
3. Edit the Deployment so `SMTP_HOST` and `SMTP_PORT` come first and `SMTP_URL` last; the rollout starts pods whose logs show `send status 200`.
