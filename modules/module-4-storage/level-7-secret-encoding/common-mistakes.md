# Common mistakes: level 7

**Trusting `base64 -d` on screen.** The decoded text looks perfect, and the newline stays invisible. Pipe it through `od -c` or `wc -c` and compare with the password's length.

**Re-encoding the value with `echo` again.** `echo mypass | base64` puts the newline back. Use `echo -n`, `printf`, or better `kubectl create secret generic --from-literal`.

**Fixing the Secret and then waiting for nothing.** The file in the pod refreshes only after kubelet's next sync, which can take a minute or more; until then the pod still sees the old file. After changing the Secret, restart the Deployment, or retry the check after a minute.
