**Deleting every release Secret with `-l owner=release-deployer`.** The pile is gone and `kubectl get secrets` is instant, but you deleted the record of the deployed release and its predecessor, so a rollback is impossible. Keep the newest two.

**Using the `status=superseded` selector for the cleanup.** It looks careful, and it spares the deployed release, but the previous release is superseded too and is deleted with the rest. Select by revision number or delete by name.

**Pruning the pile and leaving the rest.** The list calls get fast, but the syncer still hits the API server four times a second and the deploy tool still keeps everything: the next deploy adds a release and nothing is ever removed. A bounded history and a sane poll interval are the actual fixes.
