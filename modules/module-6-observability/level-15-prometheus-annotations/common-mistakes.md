# Common Mistakes — Invisible Metrics

## Mistake 1: Adding annotations to the Service, not the Pod

**Wrong approach:** Prometheus annotation scraping is done at the pod level (or via ServiceMonitor)

**Correct approach:** Add annotations to spec.template.metadata.annotations in the Deployment/Pod spec

## Mistake 2: Using wrong annotation prefix

**Wrong approach:** Using monitoring.io/scrape instead of prometheus.io/scrape

**Correct approach:** The exact annotation key matters; check your Prometheus config for the expected annotation prefix
