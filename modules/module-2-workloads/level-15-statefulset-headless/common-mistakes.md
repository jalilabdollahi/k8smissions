# Common Mistakes — The Headless Mystery

## Mistake 1: Adding clusterIP: None to existing Service via kubectl apply

**Wrong approach:** kubectl apply cannot change clusterIP on an existing Service — it returns an error

**Correct approach:** Delete the old Service first, then create with clusterIP: None

## Mistake 2: Assuming any Service name works

**Wrong approach:** StatefulSet does not validate serviceName at creation — the error is silent until pods need DNS

**Correct approach:** Always verify the referenced service exists and has clusterIP: None
