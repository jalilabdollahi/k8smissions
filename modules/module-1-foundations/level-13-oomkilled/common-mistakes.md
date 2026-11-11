## Common mistakes

- **Raising `requests.memory` only.** The request is a scheduling hint. The 64Mi limit still kills the process, and a request above the limit is rejected by the API server.
- **Deleting the limit.** The pods stop dying, but a container without a limit can use all the node's memory. The check requires the limit to stay.
- **Staring at `kubectl logs` for an error.** The process is killed from outside, so no error line is ever printed. The evidence is `Last State` in `describe pod` and the exit code 137.
- **Picking a limit just barely above 150Mi.** The interpreter and the cache need more than the cache alone. Leave headroom, and check the pods for a while before calling it fixed.
