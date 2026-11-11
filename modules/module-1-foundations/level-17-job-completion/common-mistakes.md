## Common mistakes

- **Looking at the pods only.** They are `Completed` and their logs end in `ok`. The failure is a Job condition, visible in `describe job`.
- **Editing the Job to change the deadline.** A finished Job keeps its `Failed` condition and will not run again, so the edit changes nothing useful; and some fields are immutable altogether. Delete and recreate.
- **Raising `backoffLimit`.** That counts pod failures; no pod failed here. The Job was stopped by the clock.
- **Starting the third shard by hand.** A separate pod does not make the Job `Complete`, and the check wants the Job itself to show 3 completions.
