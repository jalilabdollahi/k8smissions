## Mistakes on this level

- **Trusting that the PDB exists.** The object being present proves nothing; check `expectedPods` and `ALLOWED DISRUPTIONS` in `get pdb`.
- **Raising `minAvailable` to 3.** After the selector is right this allows 0 disruptions and no member can ever be drained. The validator requires exactly one allowed disruption.
- **Changing the pod labels to match the typo.** That edits the StatefulSet template and restarts the quorum for no reason; the selector is the wrong part.
- **Creating a second PDB.** Two budgets selecting the same pods make evictions fail with an error. Fix the one that exists.
