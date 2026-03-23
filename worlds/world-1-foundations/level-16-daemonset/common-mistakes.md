# Common Mistakes — The Everywhere Pod

## Mistake 1: Adding toleration for wrong taint key

**Wrong approach:** Adding node.kubernetes.io/not-ready — that is for eviction, not scheduling

**Correct approach:** Match the exact taint key: node-role.kubernetes.io/control-plane

## Mistake 2: Using wrong effect

**Wrong approach:** Specifying effect: NoExecute but the taint has NoSchedule — they must match exactly

**Correct approach:** Check the taint effect with kubectl describe node before writing the toleration
