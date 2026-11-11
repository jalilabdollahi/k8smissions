## Fixing only the Ingress

After the 503 is gone the page loads, which feels like done. The scraper still gets "connection refused" because the `metrics` port is UDP; both ports have to work.

## Deleting the `metrics` port from the Service

It removes the symptom for the scraper and makes the Ingress check pass, but monitoring loses its endpoint and the objective says both named ports stay.

## Renaming the Service port to `web`

The validator expects the ports to stay `http` and `metrics`, and other consumers may depend on those names. Change the single wrong reference in the Ingress instead.
