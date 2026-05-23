# Implementation Plan: Parallel QA Track

**Branch**: `001-parallel-qa-track` | **Date**: 2026-05-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-parallel-qa-track/spec.md`

## Summary

Add an independent QA pipeline that shadows the existing sf-ticket-to-pr dev workflow. Two new GitHub Actions jobs (`qa-plan` and `qa-execute`) run alongside the existing `triage` → `execute` pipeline without modifying it. `qa-plan` generates requirements-driven test scenarios from the issue text (no org needed); `qa-execute` waits for both the dev deploy and the test plan, then runs data tests (SOQL/API) and e2e tests (Playwright) against the scratch org, posting results as a PR comment.

## Technical Context

**Language/Version**: Bash (workflow glue), YAML (GitHub Actions), Claude Code skills (Markdown + prompt engineering)

**Primary Dependencies**: GitHub Actions, Claude Code Action (`anthropics/claude-code-action@v1`), Salesforce CLI (`sf`), Playwright (Chromium), `gh` CLI

**Storage**: GitHub Actions artifacts (test plan passing between jobs), git (screenshots committed to PR branch), GitHub Actions artifact store (videos)

**Testing**: End-to-end validated by running the workflow on a test issue; individual skills testable locally via Claude Code

**Target Platform**: GitHub Actions (ubuntu-latest runners)

**Project Type**: CI/CD pipeline extension + Claude Code skills

**Performance Goals**: qa-plan < 2 min (no org, text analysis only); qa-execute data phase < 30s; qa-execute e2e phase < 5 min; total QA overhead < 5 min wall-clock beyond dev track

**Constraints**: Must not modify existing triage or execute jobs; must share scratch org via existing cache mechanism; Claude API cost budget — qa-plan uses sonnet (cheap, text-only), qa-execute uses sonnet with max-turns cap

**Scale/Scope**: Initially 3 type modules (Flow, Prompt Template, Agentforce); typically 5-15 test scenarios per issue

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is not yet ratified for this project. No gates to enforce. Proceeding.

## Project Structure

### Documentation (this feature)

```text
specs/001-parallel-qa-track/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── test-plan-schema.md
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
.github/
├── workflows/
│   └── sf-ticket-to-pr.yml       # Modified: add qa-plan + qa-execute jobs
└── scripts/
    └── report-ai-cost.sh         # Existing, reused by new jobs

.claude/skills/
├── sf-ticket-to-pr/              # Existing, unchanged
├── qa-plan/                      # NEW — test plan generation from requirements
│   └── SKILL.md
├── qa-run/                       # NEW — test execution (data + e2e)
│   └── SKILL.md
└── qa-eval/                      # NEW — results evaluation + PR reporting
    └── SKILL.md

.claude/skills/_qa-types/         # NEW — type-specific testing modules
├── flow/
│   ├── plan.md                   # Flow-specific test scenario patterns
│   ├── data.md                   # DML trigger patterns, record creation
│   ├── run.md                    # SOQL assertions, Playwright scenarios
│   └── eval.md                   # Root cause analysis for Flow failures
├── prompt-template/
│   ├── plan.md                   # API invocation scenario patterns
│   ├── data.md                   # Test data for prompt inputs
│   ├── run.md                    # Output quality assertions
│   └── eval.md                   # Output quality root cause analysis
└── agentforce/
    ├── plan.md                   # Multi-turn conversation scenario patterns
    ├── data.md                   # Agent config and test data
    ├── run.md                    # Session tracing assertions
    └── eval.md                   # Conversation quality analysis

.claude/skills/_qa-shared/        # NEW — shared QA modules
├── type-detection.md             # Infer SF metadata type from issue text
├── type-registry.md              # Registry of supported types + module paths
├── sf-assertions.md              # SOQL assertion patterns, data verification
└── sf-reporting.md               # PR comment formatting, artifact management
```

**Structure Decision**: Skills-based architecture matching the existing sf-ticket-to-pr pattern. QA skills live alongside existing skills in `.claude/skills/` and are installed globally via `install-sf-ai-tools.sh`. Type modules use the `_qa-types/` prefix convention (underscore = internal/shared, not directly invoked). Workflow changes are purely additive — two new jobs appended to the existing YAML.

## Design Decisions

### D1: Skills placement — project-local vs shared repo

**Decision**: QA skills (`qa-plan`, `qa-run`, `qa-eval`, `_qa-types/`, `_qa-shared/`) live in the `salesforce-ai-tools` shared repo (same as `sf-ticket-to-pr` and other skills) and are installed globally via `install-sf-ai-tools.sh`.

**Rationale**: The existing `sf-ticket-to-pr` skill already lives in the shared repo and is symlinked globally. QA skills are reusable across any Salesforce project using the butler workflow, not specific to this extension repo. The workflow YAML in `.github/workflows/` is project-specific and stays here.

**Alternatives considered**: Keeping skills in this repo — rejected because it would require per-project installation and wouldn't benefit other repos using the same workflow pattern.

### D2: qa-plan — no org access

**Decision**: qa-plan runs without a scratch org. Type detection is text-based (parsing issue body + triage comment for keywords like "Flow", "Apex trigger", "Prompt Template").

**Rationale**: Enables parallel execution with the dev track (no org contention). The issue text and triage comment contain enough signal — "create a record-triggered Flow" is unambiguous. Text-based detection is faster and cheaper than org queries.

**Fallback**: If type detection accuracy drops below 90% in practice, add optional org access via a lightweight `sf org display` call to verify detected types.

### D3: qa-execute phases — data-first, then e2e

**Decision**: Phase 1 (data tests via SOQL/API) runs before Phase 2 (e2e via Playwright). If Phase 1 has critical failures, Phase 2 is skipped.

**Rationale**: Data tests are 100x faster (~2-5s vs ~15-20s per scenario) and catch logic bugs that would also fail e2e tests. Running data-first provides fast feedback and avoids burning Playwright time on fundamentally broken automations.

### D4: Reporting — report-only mode

**Decision**: QA findings are posted as a PR comment with screenshots committed to `.verification/qa/`. No auto-fix or re-trigger of the dev track in v1.

**Rationale**: Auto-fix requires the QA agent to understand the dev agent's code well enough to patch it — that's a significantly harder problem. Report-only gives immediate value (humans see failures with evidence) while deferring complexity.

### D5: Claude model selection for QA jobs

**Decision**: Both qa-plan and qa-execute use `claude-sonnet-4-6` (matching the existing triage and execute jobs). qa-plan gets `--max-turns 15` (lightweight text analysis), qa-execute gets `--max-turns 45` (multi-phase testing).

**Rationale**: Sonnet is the cost-performance sweet spot for CI. qa-plan is purely text analysis (reading issue + generating scenarios) so low turns. qa-execute needs more turns for data setup, Playwright interaction, evaluation, and reporting — but fewer than execute's 90 since it's not writing code.

### D6: Test plan artifact format

**Decision**: Test plan is a structured Markdown file uploaded as a GitHub Actions artifact. Sections: metadata (issue number, detected types), data test scenarios (numbered, with preconditions/actions/assertions), e2e test scenarios (with navigation steps and screenshot points).

**Rationale**: Markdown is human-readable (inspectable in the Actions UI), parseable by the qa-execute Claude agent, and doesn't require a schema validator. JSON was considered but adds parsing overhead without benefit — the consumer is an LLM, not a program.

### D7: Scratch org concurrency

**Decision**: qa-execute uses the same `concurrency.group: scratch-org-${{ needs.triage.outputs.scratch_key }}` as execute, ensuring they never run simultaneously against the same org.

**Rationale**: qa-execute reads org state (SOQL queries, UI navigation) and creates test data. Running concurrently with execute (which deploys code) would cause race conditions. The `needs: [execute, qa-plan]` dependency already serializes them, but the concurrency group is a safety net.

## Complexity Tracking

No constitution violations to justify — constitution is not yet ratified.
