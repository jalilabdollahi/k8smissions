## Editing the Deployment's own annotations

`kubectl annotate deploy payments-api ...` changes the Deployment object. The pods are created from `spec.template.metadata`, so nothing reaches them and the target list stays empty.

## Leaving `true` or the port unquoted

YAML reads `true` and `9102` as a boolean and a number; annotation values must be strings, and the API server refuses the patch with an unmarshal error. Quote every value.

## Stopping when the target appears

A target that is listed but `down` is still wrong. The annotation values copied from another service pointed at port 8080 and `/actuator/prometheus`, which this app does not serve; the scraper's `lastError` shows the 404 and the URL.

## Changing the scraper

`prom-lite` is correct, it did what it was told. The validator requires its Deployment unchanged.
