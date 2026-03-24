# Common Mistakes — API Server Writes Fail

## Mistake 1: Deleting random resources to free space

**Wrong approach:** Randomly deleting ConfigMaps or Secrets to try to free etcd space — causes outages

**Correct approach:** Defragment first (immediate space recovery), then investigate what's filling etcd (usually event history)
