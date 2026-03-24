# Common Mistakes — The Missing File

## Mistake 1: Adding the key to data but not items

**Wrong approach:** Adding logging.properties to the ConfigMap but not to the volume items list

**Correct approach:** Both ConfigMap data AND volume items must include the key

## Mistake 2: Recreating the pod after editing ConfigMap

**Wrong approach:** Expecting the pod to see new ConfigMap data immediately without updating volume items

**Correct approach:** If items: is specified, the pod spec must be updated to add new keys
