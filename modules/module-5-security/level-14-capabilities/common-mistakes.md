## Mistakes on this level

- **Adding only `NET_BIND_SERVICE`.** Port 80 is the last error in the chain, but nginx fails earlier, on `chown` and `setgid`. Each fix reveals the next missing capability.
- **Removing `drop: ["ALL"]`.** It works, because the runtime default set is back, and it throws away the baseline the security team wants. The validator requires `ALL` in `drop`.
- **Using `privileged: true`, `SYS_ADMIN` or `add: ["ALL"]`.** Everything starts, and the container is now one step from root on the node. The validator reads the process's real `CapEff` and rejects dangerous bits.
- **Restarting without reading the new error.** Every attempt prints a different line in `logs --previous`; read it, it names the operation and so the capability.
