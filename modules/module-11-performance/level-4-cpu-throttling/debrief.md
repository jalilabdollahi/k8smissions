# Latency Spikes

## What Was Broken
CPU requests were equal to limits (100m = 100m, Guaranteed QoS). This means the container gets exactly 0.1 CPU and no more. Even brief CPU bursts (during GC, request spikes) hit the limit and cause CFS throttling — injecting latency.

## The Fix
Set CPU limit much higher than request (e.g., 10x) or remove the CPU limit. Keep the request accurate for scheduling; use limits for burst control.

## Why It Matters
CPU throttling vs memory: memory limits cause OOMKill (immediate, obvious). CPU limits cause throttling (silent, shows as latency). Most latency-sensitive applications should have NO cpu limits — only cpu requests for scheduling accuracy.

## Pro Tip
Measure throttling: kubectl exec <pod> -- cat /sys/fs/cgroup/cpu/cpu.stat | grep throttled_time. If throttled_time is climbing, the container is being CPU-throttled.

## Concepts
CPU throttling, CFS bandwidth, cpu limits vs requests, latency, P99 latency
