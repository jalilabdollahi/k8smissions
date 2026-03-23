# Common Mistakes — Webhook Ignored

## Mistake 1: Using both commits[0].sha and head_commit.id

**Wrong approach:** Including both fields hoping one works — one will be empty and may cause race conditions

**Correct approach:** Identify the correct field by inspecting actual webhook payloads
