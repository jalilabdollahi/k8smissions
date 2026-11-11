## Recreating status-page with the port in the manifest

It fails the same way, with the same allocation error. The port is held by another Service; the change to `status-page` is not what is wrong.

## Picking a different port that works

A free port such as 30081 gets `status-page` answering, but the runbook and the firewall only know 30080. The goal is that exact number.

## Deleting the wrong Service

Deleting `status-page` loses the working pods' Service and does not free 30080. Check which Service actually shows 30080 in `kubectl get svc -A` before deleting.
