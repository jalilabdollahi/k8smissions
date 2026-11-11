## Setting a request on the busy container only

`web` already has a request. The HPA needs one for every container, so adding or raising it on `web` leaves `<unknown>` exactly as it was.

## Blaming metrics-server

`kubectl top pods` returns numbers, so metrics-server is healthy. The error names a container and a missing request; read the HPA's events before touching add-ons.

## Scaling the Deployment by hand

`kubectl scale` makes the number of pods look right for a moment, but the HPA still cannot read utilisation and will keep fighting you. The autoscaler needs to work, not be bypassed.
