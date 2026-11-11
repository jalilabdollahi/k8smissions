## Mistakes on this level

- **Tolerating only the taint named in the event.** The message lists one taint at a time. After the first toleration the pods are still Pending on `team=data`. Read the node, not just the event.
- **Removing the taints.** The pods schedule, but the dedicated pool is open to everyone. The validator requires both taints to remain and tests that an untolerating pod is still refused.
- **A toleration with `operator: Exists` and no key.** It tolerates every taint, including ones added later, such as a node that is unreachable. Name the keys.
- **Adding tolerations to `web-frontend` or removing the nodeSelector.** Tolerations never repel; the frontend's isolation comes from having none. Leave it as it is.
