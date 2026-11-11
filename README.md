# K8sMissions ☸️⚔️

![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20-blue)
![shell](https://img.shields.io/badge/shell-bash-brightgreen)
![kubernetes](https://img.shields.io/badge/kubernetes-learning-6366f1)

> **Learn Kubernetes by breaking it — then fixing it.**

K8sMissions is a fully local, game-based Kubernetes training platform with a rich terminal interface. Each mission drops a deliberately broken cluster in front of you. Your job is to diagnose and fix it using real `kubectl` commands.

**200 progressive challenges across 12 modules — beginner to production SRE.**  
No cloud. No AWS. No costs.

**Design and implementation by: Jalil Abdollahi**  
Email: `jalil.abdollahi@gmail.com`

---

## ✨ Features

- 🗡️ **200 missions** across 12 modules — from pod crashes to multi-failure war games
- 🏆 **XP & progression system** — earn points, unlock modules, track your journey
- 💡 **Progressive hints** — unlock gradually, only if you need them
- 📖 **Post-mission debriefs** — learn *why* your fix worked, with real-world examples
- ⏱️ **Time tracking** — see how long each mission takes vs. the estimated time
- 🧪 **Dry-run mode** — run the checks without completing the level
- 👁️ **Watch mode** — auto-validates your cluster every 5 seconds
- 🏅 **Module certificates** — earn a rich terminal certificate for each module completed
- 🧹 **Clean slate per level** — every level starts from the same baseline, whatever earlier levels left behind
- 🧰 **Real tools** — Helm, Kustomize, Argo CD and Tekton levels run against the real projects, installed on demand
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
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | *(must be running; give it 4 GB RAM, 6 GB for modules 7–8)* |
| [kind](https://kind.sigs.k8s.io/) | `brew install kind` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `brew install kubectl` |
| Python **3.9+** | `brew install python@3.11` |
| [Helm](https://helm.sh/) | `brew install helm` *(module 7)* |

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
| `check` | `1` | Validate your fix and complete the level |
| `check-dry` | `d` | Run the checks without completing the level |
| `watch` | `w` | Re-run the checks every 5 seconds |
| `hint` | `2` | Next hint (three per level, free) |
| `reveal` | | The full answer after all hints (-50% XP) |
| `guide` | `3` | Walkthrough, where a level has one |
| `debrief` | `4` | Post-mission debrief |
| `kubectl <args>` | `5 <args>` | Run kubectl from the game prompt (guarded) |
| `reset` | `6` | Rebuild this level's broken state |
| `status` | `7` | Progress and XP |
| `skip` | `8` | Skip the level (no XP) |
| `quit` | `9` | Save and exit |

---

## 🛡️ The Practice Cluster

`install.sh` creates a dedicated kind cluster, `k8smissions`, from `kind-config.yaml`
(Kubernetes 1.36, one control plane and two workers). Levels are written and tested
against exactly this shape.

- 🧹 Before each level the engine returns the cluster to a clean baseline: level
  namespaces and every object a level created (CRDs, webhooks, ClusterRoles, PVs…)
  are deleted, nodes are uncordoned and level taints and labels removed.
- 🧰 Add-ons (metrics-server, ingress-nginx, Tekton, Argo CD) are installed the first
  time a level needs them, from pinned upstream releases.
- ⚠️ Your second terminal uses your normal kubeconfig with full admin rights on the
  practice cluster. Check `kubectl config current-context` says `kind-k8smissions`
  before you start, so you never fix a "broken" production cluster by accident.
- 🚫 The game's built-in `kubectl` shortcut also refuses to delete system namespaces,
  nodes or CRDs.

---

## 🗺️ Learning Path — 12 Modules · 200 Levels · 41,000 XP

| # | Module | Levels | XP | Difficulty | Key Topics |
|---|-------|--------|----|-----------|------------|
| 1 | 🟢 Foundations | 20 | 2,700 | Beginner → Intermediate | Pods, crash/pull/pending, env, ConfigMaps, Secrets, labels, Services, init containers, Jobs |
| 2 | 🟢 Workloads | 15 | 2,250 | Beginner → Advanced | Deployments, rollouts and rollbacks, probes, HPA, PDBs, blue-green, canary, StatefulSets |
| 3 | 🟡 Networking | 15 | 2,800 | Intermediate → Expert | Services in depth, DNS, Ingress, NetworkPolicy ingress and egress |
| 4 | 🟡 Storage | 15 | 2,550 | Intermediate → Expert | PV/PVC binding, StorageClasses, access modes, reclaim policies, volume permissions |
| 5 | 🟡 Security | 15 | 2,950 | Intermediate → Expert | RBAC, securityContext, capabilities, Pod Security Admission, quotas, priority |
| 6 | 🔴 Observability | 15 | 2,800 | Intermediate → Expert | Events, logs, `kubectl top`, exit codes, probe design, debug containers, scraping |
| 7 | 🔴 GitOps | 15 | 3,150 | Advanced | Helm, Kustomize, Argo CD sync, hooks, self-heal, drift (real Argo CD) |
| 8 | 🔴 CI/CD & Pipelines | 18 | 3,800 | Advanced | Tekton tasks, params, workspaces, results, finally, sidecars, auth, gates (real Tekton) |
| 9 | 🔴 Advanced Scheduling | 18 | 3,700 | Advanced | Taints, affinity, topology spread, preemption, extended resources, DRA, descheduler |
| 10 | ⚫ Operators & CRDs | 18 | 4,500 | Expert | CRD schemas and versions, conversion, controllers, finalizers, admission webhooks |
| 11 | ⚫ Performance & SRE | 18 | 4,400 | Expert | CPU throttling, memory sizing, DNS ndots, timeouts, rollout speed, SLOs measured live |
| 12 | ⚫ Production War Games | 18 | 5,400 | Expert | Multi-cause incidents with real faults across all earlier modules |

---|-------|--------|----|-----------|------------|
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
├── play.sh / install.sh        ← Launch the game / one-time setup
├── kind-config.yaml            ← The reference practice cluster
├── engine/
│   ├── engine.py, ui.py        ← Game loop and terminal UI
│   ├── reset.py                ← Clean baseline + broken state for each level
│   ├── addons.py               ← Pinned add-ons installed on demand
│   └── safety.py               ← Guard for the in-game kubectl shortcut
├── scripts/
│   ├── test_levels.py          ← End-to-end level tests on throwaway kind clusters
│   ├── lint_levels.py          ← Static level rules
│   ├── check_duplicates.py     ← Catches template-made or near-duplicate levels
│   └── generate_registry.py    ← Regenerate levels.json
├── docs/
│   ├── LEVEL_AUTHORING.md      ← How a level is written and tested
│   └── curriculum/             ← One design map per module
└── modules/
    └── module-N-*/
        ├── _fixtures/          ← Helpers shared by the module's levels
        └── level-N-*/
            ├── mission.yaml    ← Briefing, objective, XP, required add-ons
            ├── setup.sh / broken.yaml  ← The broken state
            ├── validate.sh     ← Proves the fix by behaviour
            ├── solution.sh     ← Reference fix, typed as a player would
            ├── hint-1..3.txt, reveal.md
            └── debrief.md, common-mistakes.md
```

## 🧪 Writing and Testing Levels

Every level must fail on an empty cluster, fail on its broken state, pass after its
reference solution, and leave nothing behind:

```bash
venv/bin/python scripts/test_levels.py module-3-networking/level-5-networkpolicy --mirror
venv/bin/python scripts/lint_levels.py module-3
venv/bin/python scripts/check_duplicates.py module-3
```

`test_levels.py` runs on its own kind cluster (never the game cluster);
`--mirror` adds a local docker.io pull-through cache. See `docs/LEVEL_AUTHORING.md`.

---

## 🔄 Resetting Levels

Stuck on a level? Reset it to the original broken state:

```bash
# From inside the game: press 6 or type "reset"

# Or from the terminal directly:
venv/bin/python engine/reset.py modules/module-1-foundations/level-3-imagepull
```

---

## 🎓 Post-Mission Debriefs

After every mission you unlock a debrief written for that level:

- 🔎 What was broken and the evidence that pointed to it
- 🧠 Why Kubernetes behaved that way
- 🔧 The fix, and how it differs in a production cluster
- 🚨 The mistakes players typically make on this exact level
- ⌨️ The `kubectl` commands worth remembering

---

## ⭐ Support the Project

If K8sMissions helped you learn Kubernetes:

- 🌟 **Star this repo** — helps others discover it
- 🐛 **Open an issue** — report bugs or suggest new levels
- 🤝 **Contribute** — see [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📖 Contributing

Want to add missions or improve existing ones? See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide — including `mission.yaml` field rules, level format, and engine architecture.

---

## 📄 License

MIT License. See [LICENSE](LICENSE).
