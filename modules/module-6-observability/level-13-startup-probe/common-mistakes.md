## A startupProbe with the default numbers

`periodSeconds: 10` and `failureThreshold: 3` give 30 seconds, the same as the liveness probe that is already failing. The startup probe then kills the container at exactly the same time.

## Stretching the liveness period

Setting `periodSeconds: 300` stops the kills but a hung indexer would then be restarted only after many minutes. The validator caps period times threshold at 60 seconds.

## Removing the liveness probe

The pods would boot and become Ready, but nothing would ever restart a hung indexer. The probe has to stay.
