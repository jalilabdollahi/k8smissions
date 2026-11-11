Revision 3 renamed the ConfigMap key from `payload` to `body`, but the container still reads `/cfg/payload`, so its pods crash-loop. Revision 4 tried to add a CPU request of 500 cores on top and timed out. Revision 2 is the last one that served traffic.

1. `helm history webapp -n k8smissions` shows four revisions; 3 is `superseded`, 4 is `failed`.
2. `helm get manifest webapp --revision 3` shows the key `body`; revision 2 shows `payload`.
3. `helm rollback webapp 2 -n k8smissions --wait` creates revision 5 with revision 2's manifest and values.

A bare `helm rollback webapp` goes to revision 3, which is also broken.
