# Common Mistakes — Label Not Found

## Mistake 1: Adding a wrong label to a node

**Wrong approach:** Labeling node with accelerator-type=nvidia-a100 when pod wants v100 — still no match

**Correct approach:** Labels must match exactly including the value; check both key AND value
