# Common Mistakes — Control Plane Flood

## ❌ Restarting the API server pod
This doesn't fix the root cause — the flood resumes immediately.

## ❌ Not scaling other flood sources
Check all namespaces, not just the one you're focused on.
