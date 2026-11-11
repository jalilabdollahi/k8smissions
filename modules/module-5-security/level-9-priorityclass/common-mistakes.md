## Mistakes on this level

- **Editing `platform-critical` to flip the policy.** The API server refuses: the field is immutable. Delete-and-recreate technically works, but a new class with a new name is the safer path.
- **Scaling `batch-reindex` down to make room.** It frees the CPU, but the point of preemption is that nobody has to do this by hand. The validator requires the original 2 replicas.
- **Raising the value further.** The value was never the problem: with `Never` no value will evict anyone.
- **Setting `globalDefault: true` on the new class.** Every pod without a class, including the batch work, would take that priority and the ordering you wanted disappears. It is rejected.
