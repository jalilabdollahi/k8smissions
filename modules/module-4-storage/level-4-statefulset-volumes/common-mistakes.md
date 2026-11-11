# Common mistakes: level 4

**Patching the StatefulSet to add volumeClaimTemplates.** The API server rejects changes to that field (`updates to statefulset spec for fields other than ... are forbidden`). Delete and recreate the StatefulSet instead.

**Deleting the pods or scaling the set to get member 1 going.** The pod restarts, mounts the same shared directory and finds the same foreign owner. Fix the volume wiring, not the symptom.

**Recreating the StatefulSet with templates but keeping `pgdata-shared`.** The leftover claim still holds the first member's `node-id`, so a member that is bound to it starts with a foreign owner again. Remove the shared claim and the old `volumes` entry, so every member starts with a fresh, separate directory.
