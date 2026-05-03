# SUMM-Powers Domain Language

> Last updated: 2026-05-03
> Update rule: Update inline during discussions. Don't batch updates.

## Core Concepts

### Skill
**Definition:** A self-contained markdown document (SKILL.md) that guides agent behavior through a structured workflow.
**Examples:** `brainstorming` skill guides ideation; `test-driven-development` skill enforces TDD discipline.
**See also:** Workflow Pipeline, SKILL.md

### Workflow Pipeline
**Definition:** The ordered sequence of skills that guides a feature from idea to deployment: brainstorming → worktree → planning → execution → code review → branch finish → deploy → value proof.
**See also:** Skill, Subagent-Driven Development

### Subagent-Driven Development
**Definition:** An execution pattern where the main agent dispatches fresh subagents per task, with two-stage review (spec compliance + code quality).
**See also:** Workflow Pipeline, Executing Plans

### SKILL.md
**Definition:** The standard file name for a skill definition, containing YAML frontmatter (name, description) and markdown body with workflow instructions.
**See also:** Skill

### Domain-Aware Mode
**Definition:** A behavioral mode activated when CONTEXT.md exists — agents use defined terminology, challenge conflicts, and update terms inline.
**See also:** CONTEXT.md, Domain-Language Skill

### Design Spec
**Definition:** A validated design document produced by brainstorming, saved to `docs/superpowers/specs/`.
**See also:** Implementation Plan, Brainstorming

### Implementation Plan
**Definition:** A detailed task-by-task execution plan produced by writing-plans, saved to `docs/superpowers/plans/`.
**See also:** Design Spec, Writing Plans

### Upstream Sync
**Definition:** Cherry-pick-based synchronization from obra/superpowers (upstream) into this fork.
**See also:** .upstream-sync

## Relationships

- A **Skill** is the fundamental unit of the **Workflow Pipeline**
- **Subagent-Driven Development** is one execution strategy within the pipeline
- **Design Spec** feeds into **Implementation Plan** which feeds into execution
- **Domain-Aware Mode** activates when **CONTEXT.md** exists

## Boundaries (what things are NOT)

- A **Skill** is NOT a command — commands are thin wrappers that invoke skills
- **Workflow Pipeline** does NOT require every step — skills are invoked as needed
- **Domain-Aware Mode** is NOT a separate skill — it's a behavioral mode activated by CONTEXT.md
- **Design Spec** is NOT an implementation plan — it describes WHAT and WHY, not HOW step-by-step
