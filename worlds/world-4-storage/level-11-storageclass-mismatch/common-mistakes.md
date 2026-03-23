# Common Mistakes — The Missing Class

## Mistake 1: Editing storageClassName on existing PVC

**Wrong approach:** kubectl edit pvc to change storageClassName — this field is immutable after creation

**Correct approach:** Delete the PVC and recreate with the correct StorageClass

## Mistake 2: Assuming standard is always available

**Wrong approach:** Hardcoding 'standard' without checking kubectl get storageclass

**Correct approach:** Always verify available storage classes with kubectl get storageclass first
