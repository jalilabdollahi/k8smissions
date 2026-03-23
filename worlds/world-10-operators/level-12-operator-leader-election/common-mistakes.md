# Common Mistakes — Split Brain

## Mistake 1: Running with replicas: 1 to avoid split-brain

**Wrong approach:** Single replica has no HA — operator downtime = service downtime

**Correct approach:** Use replicas: 2+ with leader-election enabled for zero-downtime operator updates
