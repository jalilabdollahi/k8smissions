# Common Mistakes — P0 Incident

## ❌ Fixing in wrong order
Fix dependencies first. A pod can't start if its Secret doesn't exist — fix the Secret before scaling up.

## ❌ Fixing only visible issues
After fixing the obvious issues, re-check all resources — some failures only become visible after others are resolved.
