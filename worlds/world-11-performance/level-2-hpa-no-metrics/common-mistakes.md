# Common Mistakes — HPA Can't Scale

## Mistake 1: Using VPA instead of HPA

**Wrong approach:** VPA changes requests/limits vertically — doesn't add replicas for traffic spikes

**Correct approach:** HPA scales replicas for traffic; VPA right-sizes resources; use both together with care
