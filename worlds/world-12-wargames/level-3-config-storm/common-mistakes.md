# Common Mistakes — Bad Config Rollout

## ❌ Restarting pods before fixing the ConfigMap
New pods will just crash again with the same bad config.

## ❌ Not knowing which keys are required
Read the application code or Dockerfile ENV declarations to understand which env vars are mandatory.
