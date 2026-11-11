# Common mistakes: level 13

**Fixing the Secret.** The Secret's `db.password` is correct. Re-creating it or changing its value changes nothing because the file in the pod comes from the other source. Check what is in the file before changing the object that should feed it.

**Only restarting the pod.** A restart re-reads the same projected sources in the same order, and the same empty file wins again. The volume definition has to change.

**Reordering sources and calling it done.** Putting the Secret last makes it pass, but any later key in the ConfigMap with a matching name would take over again. An `items` list says explicitly which keys each source provides.
