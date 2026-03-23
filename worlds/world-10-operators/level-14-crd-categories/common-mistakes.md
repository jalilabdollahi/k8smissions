# Common Mistakes — Not in List

## Mistake 1: Creating a separate API aggregation layer to improve discovery

**Wrong approach:** Full API aggregation (APIService) is overkill just for kubectl get all visibility

**Correct approach:** Simply add categories: [all] to the CRD names — one line fix
