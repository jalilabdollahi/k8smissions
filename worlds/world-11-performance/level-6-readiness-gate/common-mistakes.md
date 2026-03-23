# Common Mistakes — Traffic to Cold Pods

## Mistake 1: Using livenessProbe with initialDelaySeconds only

**Wrong approach:** livenessProbe controls pod restart, not traffic routing — won't prevent cold pod traffic

**Correct approach:** readinessProbe controls Service endpoint inclusion; livenessProbe controls restart
