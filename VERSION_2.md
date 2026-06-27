# K8sMissions Version 2

## Product and Technical Design Document

**Document status:** Proposed  
**Audience:** Product owner, curriculum designer, software engineer, AI coding agent  
**Primary goal:** Transform K8sMissions from a collection of broken Kubernetes exercises into a structured, adaptive, and reliable learning environment.

---

## 1. Executive Summary

K8sMissions already has a valuable foundation: a real local Kubernetes cluster, practical failure scenarios, progressive hints, validation scripts, XP, modules, and a terminal-based game loop. Its main weakness is not the number of exercises; it is the learning experience around those exercises.

Version 2 should behave like an interactive Kubernetes mentor. It should teach the player how to observe a system, form a hypothesis, test that hypothesis, apply a fix, and verify the result. The game must not assume that a beginner already knows which resource to inspect, which `kubectl` command to run, how to interpret the output, or how to safely edit an immutable Kubernetes object.

The central design of Version 2 is:

```text
Learn → Observe → Diagnose → Fix → Verify → Debrief
```

The player should be able to choose how much help they receive:

- **Guided mode:** Teaches commands and reasoning step by step.
- **Standard mode:** Provides progressive hints but expects independent investigation.
- **Challenge mode:** Provides symptoms and objectives only.

The game should also gain a real editable workspace, state-aware guidance, structured validation, automated level-quality tests, richer progress tracking, and production-oriented debriefs.

Version 2 is not primarily a visual redesign. It is a redesign of the teaching model, level contract, runtime engine, and quality system.

---

## 2. Product Vision

K8sMissions should become a safe environment in which a learner develops the same mental loop used by an experienced Kubernetes engineer:

1. Identify the affected resource.
2. Inspect current state.
3. Read events, logs, and status conditions.
4. Separate symptoms from root cause.
5. Choose the smallest appropriate change.
6. Apply the change safely.
7. Verify both configuration and runtime behavior.
8. Understand why the fix worked.

The product should teach transferable troubleshooting skills rather than isolated answers.

### Product promise

> K8sMissions teaches you how to think through Kubernetes incidents—not merely how to copy the final YAML.

### Target users

Version 2 should support four user groups:

1. **Complete beginner**
   - Understands containers at a basic level.
   - Has little or no `kubectl` experience.
   - Needs commands, interpretation, and safe editing workflows.

2. **Junior DevOps or backend engineer**
   - Knows basic Kubernetes objects.
   - Needs troubleshooting practice and repetition.

3. **Certification learner**
   - Prepares for CKAD, CKA, or CKS-style tasks.
   - Needs speed, command fluency, and challenge mode.

4. **Experienced engineer**
   - Wants realistic incidents, multi-resource failures, and production trade-offs.

---

## 3. Problems in Version 1

### 3.1 Beginners are asked to discover tools they have not been taught

A mission may say that a Pod is failing, but a new player may not know:

- How to list Pods.
- Why namespace selection matters.
- When to use `get`, `describe`, `logs`, or `events`.
- How to retrieve logs from a previous container.
- How to inspect an individual container in a multi-container Pod.
- Which part of a long `describe` output matters.

A hint that merely says “look at Events” is useful only after the player understands how to reach and interpret Events.

### 3.2 The final fix is often clearer than the diagnostic path

Many educational exercises describe the root cause directly but do not teach how an engineer would discover it. This encourages answer matching rather than troubleshooting.

### 3.3 Editing live resources is inconsistent

Many Pod fields are immutable. A beginner may correctly modify `command`, `image`, resources, or volumes and still receive an API error. The game must own this complexity instead of treating it as an unexplained failure.

### 3.4 Static hints do not react to player progress

The game can repeat a command the player has already run or provide an irrelevant hint after the player has partially fixed the issue.

### 3.5 Validation is too binary

A single `PASS` or `FAIL` does not explain whether:

- The correct resource exists.
- The intended field was changed.
- The Pod is scheduled.
- The container is running.
- Readiness has passed.
- The Service has endpoints.
- Functional traffic succeeds.

### 3.6 Content defects are easy to introduce

With 200 levels, manual consistency is not sufficient. Typical risks include:

- Resource names in hints not matching manifests.
- `broken.yaml` accidentally passing validation.
- `solution.yaml` failing validation.
- Stale mission descriptions.
- Validators accepting unintended solutions.
- Reset logic leaving resources from previous levels.
- Commands referencing unavailable tools.

### 3.7 The game does not clearly separate lab fixes from production fixes

Deleting and recreating a Pod may be acceptable in a local lab but would be the wrong operational model for a Deployment-managed production workload. Players should learn this distinction.

---

## 4. Version 2 Design Principles

### 4.1 Teach the investigation path

Every beginner lesson must teach both:

- **What to change**
- **How to discover that it needs changing**

### 4.2 Progressive disclosure

Do not show everything at once. Reveal help in layers:

1. Direction
2. Command
3. Interpretation
4. Near-complete fix

### 4.3 Real Kubernetes, safe boundaries

The game should continue using a real cluster, while limiting operations to a dedicated namespace and explicitly handling exceptional cluster-scoped lessons.

### 4.4 Deterministic levels

Resetting a level must always produce the same starting condition. Applying the reference solution must reliably produce the expected successful state.

### 4.5 Explain Kubernetes behavior, not just game behavior

The player should understand why the scheduler, kubelet, controller, admission system, or networking layer behaved as observed.

### 4.6 Multiple valid solutions where appropriate

Validators should test outcomes and required invariants instead of requiring one exact YAML shape unless the lesson specifically teaches that field.

### 4.7 No hidden prerequisites

If a level requires a command, concept, editor operation, or tool that has not been taught, the level must introduce it or declare it as a prerequisite.

---

## 5. Core Player Experience

## 5.1 Learning modes

The mode should be selected when starting a new profile and changeable later.

### Guided mode

Designed for complete beginners.

- Introduces new concepts before the incident.
- Divides each mission into explicit phases.
- Shows the first useful command.
- Explains important output lines.
- Warns before unsafe or ineffective actions.
- Provides a structured fix template.
- Does not reduce XP for using normal guided steps.

### Standard mode

Designed for learners with basic knowledge.

- Shows the mission and objective.
- Provides three or four progressive hints.
- Does not automatically explain output.
- Reduces optional bonus XP when strong hints are used.

### Challenge mode

Designed for certification practice and experienced players.

- Shows symptoms, constraints, and success criteria.
- Hides commands and interpretation.
- May enforce a time target.
- Can disable the built-in editor and require direct `kubectl`.
- Awards challenge badges or bonus XP.

### Recommended implementation

Store the selected mode in the player profile:

```json
{
  "player_name": "Fatemeh",
  "learning_mode": "guided",
  "command_explanations": true,
  "editor": "code --wait"
}
```

---

## 5.2 Mission lifecycle

Each mission should move through six explicit stages.

### Stage 1: Learn

Shown only when a level introduces a new concept.

Example:

```text
NEW CONCEPT: Container logs

kubectl logs reads stdout and stderr from a container.
If a container restarted, add --previous to read the terminated instance.

Examples:
  kubectl logs my-pod -n k8smissions
  kubectl logs my-pod -n k8smissions --previous
```

The introduction should be short enough to read in under one minute.

### Stage 2: Observe

The player identifies what is unhealthy.

Example goal:

```text
Find the failing Pod and record its STATUS and RESTARTS.
```

Guided command:

```bash
kubectl get pods -n k8smissions
```

### Stage 3: Diagnose

The player gathers evidence.

Example:

```bash
kubectl logs crashloop-pod -n k8smissions --previous
kubectl describe pod crashloop-pod -n k8smissions
```

The game may ask a small comprehension question:

```text
Which evidence best explains the restart?
1. The image could not be pulled
2. The startup script does not exist
3. The Pod has no Service
```

This is not intended as a quiz-heavy product. Such questions should be used only when they reinforce interpretation.

### Stage 4: Fix

The player edits a workspace file or uses an appropriate command.

### Stage 5: Verify

The player should learn to verify manually before running the game validator.

Example:

```bash
kubectl get pod crashloop-pod -n k8smissions
kubectl logs crashloop-pod -n k8smissions
```

Then:

```text
check
```

### Stage 6: Debrief

The game explains:

- Root cause
- Evidence that revealed it
- Why the fix worked
- Alternative valid fixes
- Production-grade approach
- Commands worth remembering

---

## 6. Editable Mission Workspace

Version 2 should create a dedicated workspace for the active mission:

```text
workspace/
└── current/
    ├── README.md
    ├── mission.yaml
    ├── observed.yaml
    ├── fix.yaml
    └── notes.md
```

### `README.md`

Human-readable instructions:

- Mission name
- Current objective
- Namespace
- Suggested workflow
- How to apply `fix.yaml`
- How to reset safely

### `mission.yaml`

Structured metadata used by the engine and AI tools. This is not the Kubernetes manifest.

### `observed.yaml`

A read-only snapshot exported from the live cluster. It helps players connect live state with YAML.

### `fix.yaml`

The file the player is expected to edit and apply.

### `notes.md`

Optional personal notes. This file should survive a level reset unless the player explicitly clears it.

### Workspace behavior

When a level starts:

1. The engine resets the namespace.
2. The engine applies `setup.yaml` and `broken.yaml`.
3. The engine exports editable resources into `fix.yaml`.
4. Server-managed fields are removed.
5. The engine writes clear instructions into `README.md`.

The player can then run:

```bash
kubectl apply -f workspace/current/fix.yaml
```

For immutable standalone Pods or Jobs, provide a game command:

```text
apply
```

The engine decides whether to use:

```bash
kubectl apply -f ...
```

or:

```bash
kubectl replace --force -f ...
```

The engine must explain why recreation is necessary.

### Why a workspace matters

- Beginners can see and edit a concrete file.
- Changes are reviewable with `git diff` or a built-in diff.
- The workflow resembles declarative Kubernetes and GitOps.
- Players are not trapped inside terminal editors.
- AI assistants can inspect the same mission workspace.
- The game can compare the player’s fix with the original state without requiring an exact reference solution.

---

## 7. State-Aware Guidance

Hints should be generated from structured rules and current cluster state, not only static text.

### Example state model

```yaml
diagnostics:
  - id: pod_exists
    check:
      resource: pod/crashloop-pod
      condition: exists
    on_fail:
      message: "The expected Pod does not exist. Reset the mission."

  - id: pod_restarting
    check:
      jsonpath: .status.containerStatuses[0].restartCount
      operator: greater_than
      value: 0
    teach:
      command: kubectl logs crashloop-pod -n k8smissions --previous

  - id: command_fixed
    check:
      jsonpath: .spec.containers[0].command
      operator: not_contains
      value: /scripts/start.sh
```

### Hint behavior

If the player has already fixed the startup command but the Pod is not Ready, the game should not continue saying “fix the startup command.” It should inspect the new state and guide the player toward the remaining issue.

### Command history awareness

Version 2 may provide an optional shell wrapper or in-game command runner:

```text
run kubectl describe pod crashloop-pod
```

This allows the engine to know which commands have been attempted. Direct shell usage should still remain supported.

The game should never require command tracking for correctness. It is only a guidance enhancement.

---

## 8. Structured Hints

Replace three unstructured text files with a structured hint file:

```yaml
hints:
  - level: direction
    title: "Find the failing container"
    content: |
      Check the Pod status and restart count.

  - level: command
    title: "Read the previous container logs"
    command: kubectl logs crashloop-pod -n k8smissions --previous
    explanation: |
      CrashLoopBackOff means the current container may have just restarted.
      --previous reads output from the terminated instance.

  - level: interpretation
    title: "Interpret the error"
    content: |
      The log says /scripts/start.sh does not exist. Inspect command and args.
    command: kubectl get pod crashloop-pod -n k8smissions -o yaml

  - level: fix
    title: "Apply the correction"
    patch: |
      command: ["/bin/sh", "-c", "sleep 3600"]
```

### Hint policy

- Hint 1 points to the subsystem.
- Hint 2 gives the diagnostic command.
- Hint 3 explains the evidence.
- Hint 4 gives a near-complete fix.

For Guided mode, hints are presented as normal lesson steps. For Standard mode, they are requested manually. Challenge mode may expose only Hint 1 or disable hints.

---

## 9. Command Coach

The Command Coach explains common mistakes without becoming an unrestricted shell interceptor.

### Examples

If the player attempts:

```bash
kubectl logs service/web-service
```

The coach can explain:

```text
A Service does not run a container, so it has no container logs.
Use its selector to find the backing Pods:

  kubectl describe service web-service -n k8smissions
  kubectl get pods -n k8smissions -l app=web
```

If the player omits a namespace:

```text
No resource was found in the current namespace.
This mission uses namespace "k8smissions".
Try adding: -n k8smissions
```

If the player edits an immutable Pod field:

```text
Kubernetes does not allow this Pod field to change in place.
In this lab, the game can recreate the standalone Pod safely.
In production, you would normally update its Deployment or other controller.
```

### Scope

The coach should begin with a curated rule engine. An AI-powered coach may be added later, but core learning must not depend on an internet connection or external model.

---

## 10. Layered Validation

Each validator should return structured results rather than only an exit code.

### Proposed validation output

```json
{
  "passed": false,
  "checks": [
    {
      "id": "resource_exists",
      "status": "passed",
      "message": "Pod crashloop-pod exists"
    },
    {
      "id": "bad_command_removed",
      "status": "passed",
      "message": "Missing startup script is no longer referenced"
    },
    {
      "id": "pod_running",
      "status": "passed",
      "message": "Pod phase is Running"
    },
    {
      "id": "pod_ready",
      "status": "failed",
      "message": "Container has not become Ready yet",
      "retryable": true
    }
  ]
}
```

### Player-facing output

```text
Mission check

✓ Pod exists
✓ Broken startup command was removed
✓ Pod is Running
… Container is not Ready yet; wait a few seconds and check again
```

### Validation categories

1. **Existence**
2. **Configuration**
3. **Controller status**
4. **Runtime health**
5. **Connectivity or behavior**
6. **Safety constraints**

### Outcome-based validation

When multiple solutions are valid, validate the outcome. For example, a scheduling lesson may accept:

- Removing an impossible `nodeSelector`
- Replacing it with an existing node label
- Correctly labeling a permitted game node

If the lesson specifically teaches `nodeSelector`, its required invariant should be declared explicitly.

---

## 11. New Level Contract

Each level should have one canonical definition:

```text
levels/
└── foundations/
    └── first-pod/
        ├── level.yaml
        ├── setup.yaml
        ├── broken.yaml
        ├── solution.yaml
        ├── validation.yaml
        ├── debrief.md
        └── tests/
            ├── broken_fails.sh
            └── solution_passes.sh
```

### Proposed `level.yaml`

```yaml
apiVersion: k8smissions.io/v2
kind: Mission

metadata:
  id: foundations.first-pod
  name: Hello, Kubernetes!
  module: foundations
  order: 1
  version: 2

learning:
  difficulty: beginner
  estimatedMinutes: 8
  xp: 100
  prerequisites:
    - concepts.pod-basics
    - commands.kubectl-get
  introduces:
    - commands.kubectl-logs
    - concepts.container-entrypoint
  objectives:
    - Identify a restarting container
    - Read logs from a failed container
    - Explain how command overrides an image entrypoint

mission:
  symptom: |
    The nginx-broken Pod repeatedly restarts and never becomes Ready.
  successCriteria:
    - Pod nginx-broken is Running and Ready
    - Container no longer uses the invalid nginxzz command

resources:
  namespace: k8smissions
  editable:
    - apiVersion: v1
      kind: Pod
      name: nginx-broken

guidance:
  file: hints.yaml

validation:
  file: validation.yaml

debrief:
  file: debrief.md
```

### Benefits

- One source of truth
- Stable IDs independent of folder names
- Explicit prerequisites
- Machine-readable learning objectives
- Versioning and migrations
- Easier AI generation and review

---

## 12. Curriculum Architecture

### 12.1 Concept graph

The curriculum should be modeled as prerequisites rather than only a linear list.

Example:

```text
Pod basics
├── logs
├── command and args
├── environment variables
├── resources
└── probes

Labels
└── selectors
    └── Services
        ├── endpoints
        ├── targetPort
        └── network debugging
```

A level introducing Services should not assume the player understands labels unless that concept has already been taught.

### 12.2 Lesson types

Use several forms of exercise:

- **Introduction:** Follow a safe command sequence.
- **Single fault:** Diagnose one intentional defect.
- **Comparison:** Compare a healthy and unhealthy resource.
- **Repair:** Modify a manifest.
- **Incident:** Multiple symptoms with one root cause.
- **Boss mission:** Multiple resources and multiple faults.
- **Speed drill:** Solve a familiar pattern quickly.

### 12.3 Module structure

Each module should follow:

```text
Concept introduction
↓
Guided exercises
↓
Independent single-fault exercises
↓
Mixed review
↓
Boss incident
```

### 12.4 Suggested learning paths

After Foundations, players may choose:

- Kubernetes Application Developer
- Cluster Administrator
- Troubleshooting Specialist
- GitOps and Platform Engineering
- Kubernetes Security
- CKAD preparation
- CKA preparation
- CKS preparation

Shared levels should not be duplicated. Learning paths should reference the same stable mission IDs.

---

## 13. Debrief Design

Every debrief should use a predictable structure.

```markdown
# What happened

# Evidence that revealed the cause

# Why Kubernetes behaved this way

# The lab fix

# The production-grade fix

# Alternative valid solutions

# Commands to remember

# Common mistakes

# One-minute review
```

### Lab fix versus production fix

Example:

```text
Lab fix:
Recreate the standalone Pod after correcting its command.

Production approach:
Update the Deployment template and let its controller perform a rollout.
Do not manually repair an individual controller-owned Pod.
```

This distinction should appear whenever the lab simplifies real operational practice.

---

## 14. Progress, Scoring, and Mastery

XP alone does not represent learning. Version 2 should track mastery by concept.

### Example profile

```json
{
  "total_xp": 1420,
  "mastery": {
    "pod.lifecycle": 0.9,
    "kubectl.logs": 0.8,
    "service.selectors": 0.55,
    "storage.pvc": 0.2
  },
  "missions": {
    "foundations.first-pod": {
      "completed": true,
      "attempts": 2,
      "hints_used": 1,
      "best_time_seconds": 310,
      "mode": "guided"
    }
  }
}
```

### Scoring principles

- Guided mode should not punish beginners for learning.
- Standard mode may award bonus XP for fewer hints.
- Challenge mode may award time and no-hint bonuses.
- Replaying a level should improve mastery even if it awards little additional XP.
- Unsafe shortcuts should not earn a higher score than the intended operational solution.

### Spaced review

The game can recommend previously completed concepts:

```text
You solved Service selectors 12 days ago.
Try a two-minute review mission?
```

This should be optional.

---

## 15. Quality Assurance and Content CI

Automated level testing is a release requirement for Version 2.

### Every mission must prove:

1. All required files parse successfully.
2. Resource names referenced by mission text and hints are valid.
3. Required commands use the correct namespace.
4. The reset process succeeds.
5. The broken state fails validation for the intended reason.
6. The reference solution applies successfully.
7. The solved state passes validation.
8. A second reset removes the solved state.
9. No resources leak into protected namespaces.
10. No level requires an undeclared external binary.

### Test lifecycle

```text
Create disposable kind cluster
↓
Reset mission
↓
Assert broken state
↓
Run validator → must fail
↓
Apply reference solution
↓
Wait for declared readiness conditions
↓
Run validator → must pass
↓
Reset again
↓
Assert clean deterministic state
```

### Static checks

- Duplicate mission IDs
- Invalid prerequisite references
- Missing learning objectives
- Hints containing unknown resource names
- Validators using resources outside the mission scope
- Mission description contradicting the broken manifest
- Solution changing unrelated fields
- Deprecated Kubernetes API versions
- YAML and shell syntax errors

### Content review checklist

An AI or human reviewer should answer:

- Can a player discover the root cause using only taught commands?
- Does each hint provide new information?
- Does Hint 4 allow a blocked beginner to finish?
- Does the validator explain partial progress?
- Is the intended fix realistic?
- Is the production caveat documented?
- Is the difficulty label accurate?

---

## 16. Safety Model

### Default sandbox

- Dedicated kind cluster named `k8smissions`
- Dedicated namespace named `k8smissions`
- Restricted ServiceAccount for player actions
- Protected namespaces and cluster-critical resources
- Confirmation for destructive actions

### Cluster-scoped missions

Some lessons require Nodes, CRDs, ClusterRoles, StorageClasses, or admission policies. These should declare additional capabilities:

```yaml
safety:
  scope: cluster
  capabilities:
    - read:nodes
    - patch:nodes:labels
  cleanup:
    required: true
```

Do not grant broad cluster-admin access merely because one level needs a specific cluster-scoped operation.

### Recovery

Provide:

```text
doctor
```

The doctor command should:

- Verify Docker and kind.
- Verify the Kubernetes context.
- Detect a missing or unhealthy cluster.
- Detect leaked mission resources.
- Repair RBAC.
- Offer to recreate only the game cluster.

---

## 17. AI-Assisted Features

AI can enhance Version 2, but the game must remain fully usable without AI.

### Good AI use cases

- Explain a command output in beginner-friendly language.
- Compare player YAML with the observed resource.
- Ask Socratic diagnostic questions.
- Recommend a review mission based on weak concepts.
- Review newly authored level content.
- Generate a first draft of hints from a structured level definition.

### AI boundaries

The AI coach should receive:

- Current mission definition
- Allowed resource scope
- Sanitized cluster state
- Player mode
- Commands already attempted

It should not receive unrelated kubeconfig credentials or secrets.

### AI response policy

The coach should follow the selected mode:

- Guided: Explain command and evidence.
- Standard: Ask a leading question before revealing the command.
- Challenge: Refuse to reveal the solution unless the player explicitly exits challenge mode.

### Deterministic fallback

Every level must contain static structured hints. AI is an enhancement, never the only source of help.

---

## 18. Terminal User Experience

The terminal interface should emphasize the next meaningful action.

### Proposed mission screen

```text
╭─ Mission 2: The Infinite Restart ─────────────────────╮
│ Mode: Guided             Namespace: k8smissions       │
│ Concept: CrashLoopBackOff                             │
├───────────────────────────────────────────────────────┤
│ A Pod repeatedly restarts and never becomes Ready.    │
│                                                       │
│ Current phase: OBSERVE                                │
│ Goal: Find the failing Pod and inspect its restarts.  │
╰───────────────────────────────────────────────────────╯

Suggested command:
  kubectl get pods -n k8smissions

[1] Check phase   [2] Hint   [3] Open workspace
[4] Mission check [5] Reset  [q] Quit
```

### Proposed `check` output

```text
Diagnosis progress

✓ Located crashloop-pod
✓ Read logs from the failed container
✓ Identified missing /scripts/start.sh

Repair progress

✓ Invalid args removed
… Waiting for Pod readiness
```

### Accessibility

- Do not rely on color alone.
- Support `NO_COLOR`.
- Use consistent status symbols and text.
- Avoid animations when reduced-motion mode is enabled.
- Keep all functionality keyboard accessible.

---

## 19. Authoring Experience

Version 2 should make high-quality level creation easier.

### Proposed commands

```bash
k8smissions author new
k8smissions author lint foundations.first-pod
k8smissions author test foundations.first-pod
k8smissions author test --module foundations
k8smissions author preview foundations.first-pod
```

### New mission scaffolding

The author command should ask:

- What observable symptom does the player see?
- What is the intended root cause?
- Which concept is introduced?
- Which concepts are prerequisites?
- What evidence proves the root cause?
- What fixes are valid?
- What must the validator reject?
- What is the production-grade approach?

It should then generate the canonical files and tests.

### AI-readable authoring rule

All requirements should be explicit and machine-readable. Avoid encoding important behavior only in prose or shell scripts.

---

## 20. Recommended Technical Architecture

### Engine layers

```text
CLI / TUI
    │
Mission Orchestrator
    ├── Curriculum Service
    ├── Workspace Manager
    ├── Cluster Adapter
    ├── Guidance Engine
    ├── Validation Engine
    ├── Safety Policy
    └── Progress Store
```

### Cluster adapter

Centralize all Kubernetes operations:

- Get resource
- Apply resource
- Replace immutable resource
- Wait for condition
- Delete mission resources
- Export clean YAML
- Read logs and events

The rest of the application should not construct arbitrary `kubectl` commands in many different files.

An initial implementation may continue using `kubectl` subprocesses. A later version may use the Kubernetes Python client.

### Validation engine

Support declarative checks first, with shell validators as an escape hatch.

```yaml
checks:
  - id: pod-running
    resource: v1/Pod/nginx-broken
    assertion:
      jsonpath: .status.phase
      equals: Running

  - id: pod-ready
    resource: v1/Pod/nginx-broken
    assertion:
      condition:
        type: Ready
        status: "True"

  - id: invalid-command-removed
    resource: v1/Pod/nginx-broken
    assertion:
      jsonpath: .spec.containers[0].command[0]
      notEquals: nginxzz
```

### Progress store

Use a versioned schema. JSON is sufficient initially, but all writes should be atomic:

1. Write temporary file.
2. Flush.
3. Rename over the original.

Include migration logic:

```json
{
  "schema_version": 2
}
```

### Observability

Local diagnostic logs should record:

- Level start and reset
- Kubernetes command failures
- Validation results
- Engine exceptions

Do not record Secret values.

---

## 21. Migration Strategy

Version 2 should be introduced incrementally instead of rewriting all 200 levels at once.

### Phase 0: Quality baseline

- Add mission linting.
- Add broken-fails and solution-passes tests.
- Fix resource-name inconsistencies.
- Standardize namespace usage.
- Make reset deterministic.

### Phase 1: Foundations pilot

Convert Module 1 only:

- New `level.yaml`
- Four-level hint structure
- Editable workspace
- Layered validation
- Guided mission phases
- New debrief format

Module 1 becomes the reference implementation.

### Phase 2: Engine V2

- Curriculum/prerequisite model
- Workspace manager
- Structured validation engine
- Mode-aware guidance
- Versioned progress schema
- Doctor command

### Phase 3: Content migration

Migrate modules in risk order:

1. Foundations
2. Workloads
3. Networking
4. Storage
5. Security
6. Observability
7. GitOps
8. CI/CD
9. Scheduling
10. Operators and advanced modules

### Phase 4: Mastery and review

- Concept mastery
- Recommended review
- Learning paths
- Challenge scoring
- Boss missions

### Phase 5: Optional AI coach

- Local deterministic context builder
- Provider-agnostic AI interface
- Privacy filtering
- Mode-aware coaching policy
- Static fallback retained

---

## 22. Prioritized Backlog

### P0 — Required for a trustworthy learning product

- Automated `broken → fail` and `solution → pass` tests
- Resource-name and namespace linting
- Deterministic reset and cleanup
- Editable mission workspace
- Safe handling of immutable resources
- Guided flow for Module 1
- Structured partial validation

### P1 — Major learning improvements

- Learning modes
- Concept prerequisites
- Four-stage hints
- Production-grade debriefs
- Command Coach rules
- Doctor command
- Versioned progress format

### P2 — Retention and advanced UX

- Concept mastery
- Spaced review
- Learning paths
- Boss missions
- Time trials and challenge badges
- Improved TUI

### P3 — Optional intelligence

- AI output explanation
- AI curriculum recommendations
- AI-assisted mission authoring
- AI content review

---

## 23. Success Metrics

Version 2 should be evaluated with measurable outcomes.

### Learning metrics

- Percentage of beginners completing the first five missions.
- Percentage completing a mission without viewing the final fix hint.
- Improvement when replaying a concept after several days.
- Ability to solve a transfer problem with different resource names.

### Product metrics

- Mission reset failure rate.
- Validator false-positive and false-negative reports.
- Median time spent blocked without requesting a hint.
- Drop-off point by module and mission.
- Number of content defects detected by CI before release.

### Quality targets

- 100% of migrated missions pass lifecycle tests.
- 100% of commands in Guided mode are executable in the supported environment.
- Zero resource-name mismatches in released content.
- Zero protected-namespace mutations during ordinary missions.
- Every introduced concept has an explicit prerequisite and learning objective.

Telemetry should be opt-in and privacy-preserving.

---

## 24. Non-Goals for the Initial Version 2 Release

To control scope, the first V2 release should not require:

- A browser-based UI
- Multiplayer
- Cloud-hosted clusters
- Mandatory AI access
- A custom Kubernetes distribution
- Replacing every shell validator immediately
- Migrating all 200 levels before the pilot is validated

The first success milestone is a significantly better Module 1 backed by a reusable V2 engine and reliable content tests.

---

## 25. Risks and Mitigations

### Risk: Guided mode becomes a copy-paste tutorial

**Mitigation:** Always connect commands to a question and evidence. Ask the player to predict or interpret important output before revealing the fix.

### Risk: Supporting multiple valid fixes makes validation complex

**Mitigation:** Define explicit invariants and separate configuration checks from behavioral checks.

### Risk: Workspace state diverges from cluster state

**Mitigation:** Provide `workspace refresh`, show diffs, and clearly label generated versus player-owned files.

### Risk: Content migration becomes too large

**Mitigation:** Use Module 1 as a pilot, build conversion tooling, and migrate module by module.

### Risk: AI gives incorrect or overly direct answers

**Mitigation:** Ground it in the mission contract, restrict scope, enforce learning-mode policy, and retain deterministic hints.

### Risk: Tests are slow across 200 missions

**Mitigation:** Run static checks on every change, module-level cluster tests in parallel, and a full lifecycle suite before release.

---

## 26. Definition of Done for a Version 2 Mission

A mission is complete only when:

- It has a stable unique ID.
- Its observable symptom matches the broken cluster state.
- Its learning objectives and prerequisites are declared.
- A beginner can identify the first diagnostic command in Guided mode.
- Every hint adds new information.
- The final hint provides an executable path to completion.
- The workspace contains only relevant editable resources.
- The broken state reliably fails validation.
- The reference solution reliably passes validation.
- The validator reports partial progress.
- Reset removes all mission-created resources.
- The debrief explains evidence, root cause, lab fix, and production fix.
- Static lint and cluster lifecycle tests pass.

---

## 27. Recommended First Implementation Slice

The first implementation slice should be deliberately small and end-to-end.

### Scope

Convert the first five Foundations missions:

1. First Pod
2. CrashLoopBackOff
3. ImagePullBackOff
4. Pending resources
5. Environment variables

### Deliverables

- `level.yaml` V2 schema
- Workspace generation
- Guided/Standard/Challenge selection
- Four structured hints
- Declarative validation
- Partial check output
- Broken/solution lifecycle tests
- New debrief format
- Progress schema migration

### Acceptance test

A person with basic container knowledge but no Kubernetes troubleshooting experience should be able to:

1. Start the game without external instructions.
2. Complete the five missions in Guided mode.
3. Explain when to use `get`, `describe`, and `logs`.
4. Identify the evidence behind each root cause.
5. Repeat at least three missions in Standard mode without the final hint.

Only after this slice works well should the remaining Foundations missions be migrated.

---

## 28. Final Recommendation

The highest-value direction is not to add more levels immediately. K8sMissions already has enough content to be substantial. The next investment should make existing content teach reliably.

The recommended order is:

1. Build automated mission-quality tests.
2. Introduce the editable workspace.
3. Implement Guided mode and structured mission phases.
4. Convert Module 1 as the reference curriculum.
5. Add layered validation and production-grade debriefs.
6. Migrate the remaining modules.
7. Add mastery, learning paths, and optional AI coaching.

If Version 2 succeeds, players should leave with more than completed missions and XP. They should have a repeatable troubleshooting method, confidence using Kubernetes tools, and an accurate understanding of how Kubernetes behaves in real systems.

