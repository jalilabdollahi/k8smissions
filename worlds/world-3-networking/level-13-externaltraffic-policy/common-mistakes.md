# Common Mistakes — Lost in Transit

## Mistake 1: Assuming packet loss is a network provider issue

**Wrong approach:** Filing infrastructure tickets before checking externalTrafficPolicy

**Correct approach:** Check Service YAML for externalTrafficPolicy: Local before escalating

## Mistake 2: Using Local everywhere for client IP

**Wrong approach:** Setting Local on services with sparse pod distribution — causes silent drops

**Correct approach:** Use Local only when pods are on every node OR when paired with a load balancer that checks pod presence
