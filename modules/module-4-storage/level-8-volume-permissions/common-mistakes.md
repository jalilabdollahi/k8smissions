# Common mistakes: level 8

**Running the pod as root.** Setting `runAsUser: 0` makes the key readable and the crash goes away, but the check requires a non-root user. Security forbade this; the permission model is the thing to fix.

**Opening the file mode to everyone.** `defaultMode: 0444` or `0644` lets uid 10001 read the file, but this app refuses a key that is readable by others and exits with a message about the mode. Use `fsGroup`, which grants only the group that needs access.

**Trying to chown the file in the container.** The Secret volume is read-only, and a non-root user cannot change ownership anyway. Ownership of volume files is set from the pod spec (`fsGroup`), not from inside the container.
