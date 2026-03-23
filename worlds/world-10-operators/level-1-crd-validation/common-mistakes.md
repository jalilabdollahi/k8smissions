# Common Mistakes — Rejected by the API

## Mistake 1: Deleting and recreating the CRD

**Wrong approach:** Dropping the CRD deletes all custom resources — massive data loss

**Correct approach:** Edit the schema validation in-place; no need to delete the CRD
