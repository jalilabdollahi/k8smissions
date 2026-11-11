## Common mistakes

- **Looking for logs.** A Pending pod never ran a container. The scheduler's events in `describe` are the only evidence.
- **Deleting the CPU request.** The pod would schedule, but the objective keeps a request in place so the capacity stays reserved.
- **Trying `kubectl edit pod` to change the number.** The API server rejects changes to a running pod's resources; recreate it.
- **Adding nodes or cordoning things.** The pod asks for more than any node could ever offer, so capacity is not the problem.
