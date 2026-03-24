# Common Mistakes — The Aggregation Gap

## Mistake 1: Manually adding rules to the aggregating ClusterRole

**Wrong approach:** Adding rules directly to operator-role — these get overwritten by aggregation

**Correct approach:** Add rules via source ClusterRoles with the correct aggregation label

## Mistake 2: Expecting immediate label propagation

**Wrong approach:** Adding the label and not seeing rules update immediately

**Correct approach:** The controller reconciles within seconds; check with kubectl get clusterrole <name> -o yaml
