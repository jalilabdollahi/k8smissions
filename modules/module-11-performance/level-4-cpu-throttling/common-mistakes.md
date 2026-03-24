# Common Mistakes — Latency Spikes

## Mistake 1: Setting requests = limits for Guaranteed QoS

**Wrong approach:** Guaranteed QoS means no CPU bursting — latency-sensitive apps need burst capacity

**Correct approach:** For latency-sensitive apps: accurate requests for scheduling, high/no limits for burst
