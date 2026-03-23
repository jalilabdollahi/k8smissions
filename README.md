# K8sMissions ☸️⚔️

![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-blue)
![shell](https://img.shields.io/badge/shell-bash-brightgreen)
![kubernetes](https://img.shields.io/badge/kubernetes-learning-6366f1)

> **Learn Kubernetes by breaking it — then fixing it.**

K8sMissions is a fully local, game-based Kubernetes training platform with a rich terminal interface. Each mission drops a deliberately broken cluster in front of you. Your job is to diagnose and fix it using real `kubectl` commands.

**200 progressive challenges across 12 worlds — beginner to production SRE.**  
No cloud. No AWS. No costs.

---

## ✨ Features

- 🗡️ **200 missions** across 12 worlds — from pod crashes to multi-failure war games
- 🏆 **XP & progression system** — earn points, unlock worlds, track your journey
- 💡 **Progressive hints** — unlock gradually, only if you need them
- 📖 **Post-mission debriefs** — learn *why* your fix worked, with real-world examples
- ⏱️ **Time tracking** — see how long each mission takes vs. the estimated time
- 🧪 **Dry-run mode** — test your fix before applying it, no XP penalty
- 👁️ **Watch mode** — auto-validates your cluster every 5 seconds
- 🏅 **World certificates** — earn a rich terminal certificate for each world completed
- 🔒 **Safety guards** — RBAC limits blast radius; critical namespaces are protected
- 💾 **Auto-save** — progress is saved after every completed mission
- ⌨️ **Shell completion** — tab-complete all commands in bash and zsh

---

## 🚀 Quick Start

```bash
git clone https://github.com/jalilabdollahi/k8smissions.git
cd k8smissions
./install.sh          # one-time setup (creates kind cluster + venv)
./play.sh             # start the game
```

> First run after cloning? Generate the level registry:
> ```bash
> python3 scripts/generate_registry.py
> ```

---

## 📋 Prerequisites

| Tool | Install |
|------|---------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | *(must be running)* |
| [kind](https://kind.sigs.k8s.io/) | `brew install kind` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `brew install kubectl` |
| Python **3.9+** | `brew install python@3.11` |

---

## 🎮 How to Play

1. **Run** `./play.sh` — the game loop runs here, keep this terminal open
2. **Open a second terminal** — use `kubectl` to investigate and fix the cluster
3. **Read the mission briefing** — understand what's broken and what success looks like
4. **Fix it** — apply your changes with `kubectl` in the second terminal
5. **Validate** — run `check` (or press `1`) to test your solution
6. **Earn XP** and move to the next mission

---

## 🎯 Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `check` | `1` | Validate your solution |
| `check-dry` | `d` | Dry-run — see if your fix would pass without committing |
| `watch` | `w` | Auto-validate every 5 seconds |
| `hint` | `2` | Reveal the next progressive hint |
| `solution` | `3` | Show the reference solution file |
| `guide` | `4` | Step-by-step walkthrough |
| `debrief` | `5` | Post-mission learning debrief |
| `reset` | `6` | Reset this level back to broken state |
| `skip` | `7` | Skip level (no XP awarded) |
| `status` | `8` | Show current progress and XP |
| `help` | `9` | Show all commands |
| `quit` | `q` | Save and exit |

---

## 🛡️ Safety First

K8sMissions includes RBAC-based safety guards, on by default:

- 🔐 Operations are scoped to the `k8smissions` namespace
- 🚫 Deletion of `kube-system`, `default`, and other critical namespaces is blocked
- ⛔ Destructive cluster-wide operations are prevented
- 🧸 Safe for beginners — hard to accidentally wreck things

---

## 🗺️ Learning Path — 12 Worlds · 200 Levels · 55,925 XP

| # | World | Levels | XP | Difficulty | Key Topics |
|---|-------|--------|----|-----------|------------|
| 1 | 🟢 Foundations | 20 | 3,025 | Beginner | Pods, Services, ConfigMaps, Secrets, Jobs |
| 2 | 🟢 Workloads | 15 | 2,950 | Beginner | Deployments, HPA, rollouts, StatefulSets |
| 3 | 🟡 Networking | 15 | 3,275 | Intermediate | DNS, Ingress, NetworkPolicy, Services |
| 4 | 🟡 Storage | 15 | 3,375 | Intermediate | PV, PVC, StorageClass, volume permissions |
| 5 | 🟡 Security | 15 | 4,300 | Intermediate | RBAC, SecurityContext, Pod Security Standards |
| 6 | 🔴 Observability | 15 | 3,800 | Advanced | Metrics, logs, events, tracing, debugging |
| 7 | 🔴 GitOps | 15 | 5,100 | Advanced | Helm, Kustomize, ArgoCD, production patterns |
| 8 | 🔴 CI/CD & Pipelines | 18 | 5,425 | Advanced | GitOps pipelines, Tekton, image builds |
| 9 | 🔴 Advanced Scheduling | 18 | 5,775 | Advanced | Affinity, taints, topology, priority classes |
| 10 | ⚫ Operators & CRDs | 18 | 6,225 | Expert | Custom controllers, CRDs, admission webhooks |
| 11 | ⚫ Performance & SRE | 18 | 6,075 | Expert | Profiling, resource tuning, SLOs, chaos |
| 12 | ⚫ Production War Games | 18 | 6,600 | Expert | Multi-failure incidents, live production scenarios |

---

## 🐚 Shell Completion

Tab-complete all commands in bash or zsh:

**zsh (oh-my-zsh):**
```bash
ln -sf "$PWD/completion/_k8smissions" ~/.oh-my-zsh/completions/_k8smissions
echo 'alias k8sm="$HOME/Desktop/Learning/K8s/k8smissions/play.sh"' >> ~/.zshrc
source ~/.zshrc
```

**bash:**
```bash
source completion/k8smissions.bash
```

---

## 📁 Project Structure

```
k8smissions/
├── play.sh                     ← Launch the game
├── install.sh                  ← One-time setup
├── requirements.txt            ← Python dependencies
├── engine/
│   ├── engine.py               ← Core game loop
│   ├── ui.py                   ← Rich terminal UI
│   ├── certificate.py          ← World completion certificates
│   ├── player.py               ← Player state helpers
│   ├── reset.py                ← Level reset logic
│   └── safety.py               ← RBAC safety guards
├── scripts/
│   ├── build_levels.py         ← Build all level YAML files
│   └── generate_registry.py   ← Regenerate levels.json registry
├── completion/
│   ├── _k8smissions            ← oh-my-zsh completion
│   ├── k8smissions.zsh         ← zsh completion (manual source)
│   └── k8smissions.bash        ← bash completion
├── rbac/                       ← Namespace safety manifests
└── worlds/
    ├── world-1-foundations/
    │   └── level-N-*/
    │       ├── mission.yaml    ← Briefing, hints, debrief, validator
    │       ├── broken.yaml     ← The deliberately broken manifest
    │       └── solution.yaml   ← Reference solution
    ├── world-2-workloads/
    └── ...                     ← worlds 3–12
```

---

## 🔄 Resetting Levels

Stuck on a level? Reset it to the original broken state:

```bash
# From inside the game: press 6 or type "reset"

# Or from the terminal directly:
python3 engine/reset.py level-5-image-pull       # reset one level
python3 engine/reset.py all                       # reset everything
```

---

## 🎓 Post-Mission Debriefs

After every mission you unlock a debrief that covers:

- 🔎 What actually broke and why
- 🧠 The correct mental model for the concept
- 🚨 Real-world production incident analogues
- 💼 Interview questions you can now answer
- 🔧 The `kubectl` commands you just mastered

---

## ⭐ Support the Project

If K8sMissions helped you learn Kubernetes:

- 🌟 **Star this repo** — helps others discover it
- 🐛 **Open an issue** — report bugs or suggest new levels
- 🤝 **Contribute** — see [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📖 Contributing

Want to add missions or improve existing ones? See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide — including `mission.yaml` field rules, level format, and engine architecture.
