# K8sMissions

A local, game-based Kubernetes training platform with 75 challenges across 7 worlds.

## Quick Start

```bash
./install.sh   # one-time setup
./play.sh      # start the game
```

## Prerequisites

- [kind](https://kind.sigs.k8s.io/) — `brew install kind`
- [kubectl](https://kubernetes.io/docs/tasks/tools/) — `brew install kubectl`
- Python 3.9+

## Worlds

| # | World | Levels | XP | Focus |
|---|-------|--------|----|-------|
| 1 | Foundations | 15 | 2,050 | Pods, Services, ConfigMaps, Secrets |
| 2 | Workloads | 10 | 2,050 | Deployments, HPA, rollouts, StatefulSets |
| 3 | Networking | 10 | 2,350 | DNS, Ingress, NetworkPolicy, Services |
| 4 | Storage | 10 | 2,450 | PV, PVC, StorageClass, volumes |
| 5 | Security | 10 | 3,150 | RBAC, SecurityContext, Pod Security |
| 6 | Observability ★ | 10 | 2,900 | Metrics, logs, events, debugging |
| 7 | GitOps ★ | 10 | 4,050 | Helm, Kustomize, ArgoCD, production |


**Total: 75 levels · 19,000 XP**

## Architecture
```
k8smissions/
├── play.sh                 ← Launch the game
├── install.sh              ← One-time setup
├── progress.json           ← Save file
├── requirements.txt        ← Python deps
├── engine/                 ← Python game loop (TO IMPLEMENT)
│   └── IMPLEMENTATION_NOTES.txt
├── rbac/                   ← RBAC safety manifests (TO IMPLEMENT)
│   └── RBAC_NOTES.txt
└── worlds/
    ├── world-1-foundations/
    │   └── WORLD_DESCRIPTION.txt   ← Full level specs
    ├── world-2-workloads/
    ├── world-3-networking/
    ├── world-4-storage/
    ├── world-5-security/
    ├── world-6-observability/      ← NEW
    └── world-7-gitops/             ← NEW
```

Each world's `WORLD_DESCRIPTION.txt` contains detailed specs for every level — ready for AI-assisted implementation.

## Implementation Status

- [x] install.sh — done
- [x] play.sh — done
- [x] World descriptions — done (all 7 worlds, 75 levels)
- [ ] engine/ — implement from `engine/IMPLEMENTATION_NOTES.txt`
- [ ] rbac/ — implement from `rbac/RBAC_NOTES.txt`
- [ ] Level files — implement from each `WORLD_DESCRIPTION.txt`