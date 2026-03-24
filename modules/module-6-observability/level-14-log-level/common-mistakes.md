# Common Mistakes — Log Overload

## Mistake 1: Trying to kubectl edit env on a running pod

**Wrong approach:** Environment variables cannot be changed on a running pod via edit

**Correct approach:** Delete the pod and recreate with the updated env, or use a Deployment and kubectl set env

## Mistake 2: Silencing all logs by setting NONE or empty

**Wrong approach:** Setting LOG_LEVEL to empty/NONE — errors will also be silenced

**Correct approach:** Use WARN or ERROR minimum; never silence all logs in production
