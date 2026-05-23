# Type Registry

Maps detected type names to their module paths and lists available module files. Used by qa-plan, qa-run, and qa-eval to locate type-specific logic.

## Registry

| Type Key | Module Path | Available Modules |
|----------|-------------|-------------------|
| `flow` | `~/.claude/skills/_qa-types/flow/` | plan.md, data.md, run.md, eval.md |
| `prompt-template` | `~/.claude/skills/_qa-types/prompt-template/` | plan.md, data.md, run.md, eval.md |
| `agentforce` | `~/.claude/skills/_qa-types/agentforce/` | plan.md, data.md, run.md, eval.md |

## Module Roles

Each type directory contains four modules, one per QA phase:

| Module | Phase | Used By | Purpose |
|--------|-------|---------|---------|
| `plan.md` | Planning | qa-plan | Type-specific test scenario patterns and boundary conditions |
| `data.md` | Data Testing | qa-run Phase 1 | Test data creation, DML triggers, API setup |
| `run.md` | Execution | qa-run Phase 1+2 | SOQL assertions, Playwright scenarios, screenshot points |
| `eval.md` | Evaluation | qa-eval | Root cause analysis patterns, fix suggestions |

## How to Add a New Type

1. Create a new directory: `~/.claude/skills/_qa-types/<type-key>/`
2. Add all four module files: `plan.md`, `data.md`, `run.md`, `eval.md`
3. Add the type to this registry table
4. Add detection keywords to `_qa-shared/type-detection.md`

## Module Resolution

When a skill needs to load a type module:
1. Read the detected types list from the test plan metadata (or from type-detection output)
2. For each detected type, look up the module path in this registry
3. Read the relevant module file (plan.md for qa-plan, data.md/run.md for qa-run, eval.md for qa-eval)
4. If a type is detected but not in this registry, skip it and note "unsupported type" in output
