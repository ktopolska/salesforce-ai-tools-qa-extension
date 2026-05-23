# Tasks: Parallel QA Track

**Input**: Design documents from `specs/001-parallel-qa-track/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested — test tasks omitted. Validation is via end-to-end CI workflow run.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Skills**: `.claude/skills/` in the `salesforce-ai-tools` shared repo (installed globally via `install-sf-ai-tools.sh`)
- **Workflow**: `.github/workflows/sf-ticket-to-pr.yml` in this repo
- **Scripts**: `scripts/` in this repo

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the skill directory structure and shared QA modules

- [x] T001 Create directory structure for QA skills: `.claude/skills/qa-plan/`, `.claude/skills/qa-run/`, `.claude/skills/qa-eval/`, `.claude/skills/_qa-types/{flow,prompt-template,agentforce}/`, `.claude/skills/_qa-shared/`
- [x] T002 [P] Create type detection module in `.claude/skills/_qa-shared/type-detection.md` — keyword matching rules for Flow, Prompt Template, Agentforce, Apex with context-awareness rules from research.md R3
- [x] T003 [P] Create type registry module in `.claude/skills/_qa-shared/type-registry.md` — maps detected type names to `_qa-types/<type>/` module paths, lists supported types and their module files (plan.md, data.md, run.md, eval.md)
- [x] T004 [P] Create SOQL assertion patterns module in `.claude/skills/_qa-shared/sf-assertions.md` — reusable patterns for asserting record state, field values, record counts, and related record existence via SOQL queries and `sf data query`
- [x] T005 [P] Create PR reporting module in `.claude/skills/_qa-shared/sf-reporting.md` — QA report Markdown template matching the format in data-model.md, screenshot commit instructions, video artifact upload instructions, `qa-findings` label logic

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No foundational phase needed — all shared modules are created in Phase 1 Setup. User story phases depend only on Phase 1 completion.

**Checkpoint**: Shared modules ready — skill implementation can begin.

---

## Phase 3: User Story 1 — Requirements-Driven Test Plan Generation (Priority: P1) — MVP

**Goal**: qa-plan job reads issue requirements and generates test scenarios without needing a scratch org, running in parallel with the dev execute job.

**Independent Test**: Create a test issue with requirements, run qa-plan skill locally, verify it produces a test plan artifact with correct types and scenarios.

### Implementation for User Story 1

- [x] T006 [P] [US1] Create Flow planning module in `.claude/skills/_qa-types/flow/plan.md` — Flow-specific scenario patterns: record-triggered DML, boundary conditions (field values at thresholds), before/after save triggers, bulkification scenarios
- [x] T007 [P] [US1] Create Prompt Template planning module in `.claude/skills/_qa-types/prompt-template/plan.md` — API invocation scenarios, input variation testing, output format validation, token limit edge cases
- [x] T008 [P] [US1] Create Agentforce planning module in `.claude/skills/_qa-types/agentforce/plan.md` — multi-turn conversation scenarios, topic routing, action invocation, escalation paths, context grounding checks
- [x] T009 [US1] Create qa-plan skill in `.claude/skills/qa-plan/SKILL.md` — reads issue body via `gh issue view`, reads triage plan comment, invokes `_qa-shared/type-detection.md` to detect types, loads `_qa-types/<type>/plan.md` for each detected type, generates test plan following the contract in `contracts/test-plan-schema.md`, posts summary comment on issue, outputs test plan file
- [x] T010 [US1] Add `qa-plan` job to `.github/workflows/sf-ticket-to-pr.yml` — `needs: triage`, `if: needs.triage.outputs.proceed == 'true'`, runs on `ubuntu-latest`, no scratch org, checkouts repo + salesforce-ai-tools, installs skills, invokes Claude with qa-plan skill prompt, uploads test plan as `test-plan` artifact via `actions/upload-artifact@v4`

**Checkpoint**: qa-plan job runs in parallel with execute, produces a test plan artifact from issue requirements.

---

## Phase 4: User Story 2 — Automated Data and E2E Test Execution (Priority: P1)

**Goal**: qa-execute restores the scratch org and runs data tests (SOQL/API) then e2e tests (Playwright) against it, using the test plan from qa-plan.

**Independent Test**: Provide a pre-built test plan and a scratch org with deployed code, run qa-run skill, verify it produces pass/fail results with screenshots and video.

### Implementation for User Story 2

- [x] T011 [P] [US2] Create Flow data testing module in `.claude/skills/_qa-types/flow/data.md` — record creation patterns via `sf data create record`, DML triggers for Flow activation, bulk data import for bulkification testing
- [x] T012 [P] [US2] Create Flow run module in `.claude/skills/_qa-types/flow/run.md` — SOQL assertion patterns for Flow outcomes, Playwright navigation to Flow-affected records, screenshot capture at assertion points
- [x] T013 [P] [US2] Create Prompt Template data testing module in `.claude/skills/_qa-types/prompt-template/data.md` — test input data creation, API authentication setup for template invocation
- [x] T014 [P] [US2] Create Prompt Template run module in `.claude/skills/_qa-types/prompt-template/run.md` — API invocation via `sf apex run`, output quality assertions, response format validation
- [x] T015 [P] [US2] Create Agentforce data testing module in `.claude/skills/_qa-types/agentforce/data.md` — agent configuration verification, test data for conversation scenarios, knowledge article setup
- [x] T016 [P] [US2] Create Agentforce run module in `.claude/skills/_qa-types/agentforce/run.md` — multi-turn conversation execution via Agent Runtime API, session trace extraction, topic/action coverage assertions
- [x] T017 [US2] Create qa-run skill in `.claude/skills/qa-run/SKILL.md` — downloads test plan artifact, loads `_qa-shared/sf-assertions.md`, executes Phase 1 (data tests): for each DT-NNN scenario, creates test data, triggers actions, asserts via SOQL using type-specific `data.md` and `run.md` modules; executes Phase 2 (e2e tests): logs into scratch org via frontdoor URL, for each ET-NNN scenario, navigates Playwright, records video (`recordVideo: { dir: '/tmp/qa-videos/' }`), captures screenshots at marked points; skips Phase 2 if Phase 1 has critical failures
- [x] T018 [US2] Add `qa-execute` job to `.github/workflows/sf-ticket-to-pr.yml` — `needs: [execute, qa-plan]`, `if: needs.execute.result == 'success' && needs.qa-plan.result == 'success'`, runs on `ubuntu-latest`, `concurrency: { group: scratch-org-${{ needs.triage.outputs.scratch_key }} }`, checkouts PR branch, installs SF CLI + Playwright Chromium, restores scratch org from cache, downloads `test-plan` artifact, invokes Claude with qa-run then qa-eval skill prompts, `--max-turns 45 --model claude-sonnet-4-6`

**Checkpoint**: qa-execute runs data + e2e tests, produces results with screenshots and video.

---

## Phase 5: User Story 3 — QA Report on Pull Request (Priority: P2)

**Goal**: Post structured QA results as a PR comment, commit screenshots, upload videos, label PR on failures.

**Independent Test**: Provide evaluation results and a PR number, run qa-eval skill, verify PR comment, committed screenshots, and labels.

### Implementation for User Story 3

- [x] T019 [P] [US3] Create Flow eval module in `.claude/skills/_qa-types/flow/eval.md` — root cause analysis patterns for Flow failures (missing criteria, wrong field updates, order-of-execution issues), fix suggestions
- [x] T020 [P] [US3] Create Prompt Template eval module in `.claude/skills/_qa-types/prompt-template/eval.md` — output quality analysis, hallucination detection patterns, template variable resolution failures
- [x] T021 [P] [US3] Create Agentforce eval module in `.claude/skills/_qa-types/agentforce/eval.md` — conversation quality analysis, topic misrouting detection, action failure classification
- [x] T022 [US3] Create qa-eval skill in `.claude/skills/qa-eval/SKILL.md` — loads `_qa-shared/sf-reporting.md`, loads type-specific `eval.md` modules, compares actual vs expected for all scenarios, groups failures by root cause, classifies severity (Critical/High/Medium/Low), generates QA report Markdown per data-model.md format, posts report as PR comment via `gh pr comment`, commits screenshots to `.verification/qa/` on PR branch via `git add && git commit && git push`, uploads `/tmp/qa-videos/` as Actions artifact `qa-videos` via `actions/upload-artifact@v4`, adds `qa-findings` label if any failures via `gh pr edit --add-label`
- [x] T023 [US3] Wire qa-eval invocation into the `qa-execute` job in `.github/workflows/sf-ticket-to-pr.yml` — add cost reporting step (reuse `report-ai-cost.sh`), add failure notification step matching execute job pattern

**Checkpoint**: Full QA pipeline functional — qa-plan → qa-execute (data + e2e + eval) → QA report on PR.

---

## Phase 6: User Story 4 — Type-Specific Testing Modules (Priority: P2)

**Goal**: Ensure each type module has complete, specialized testing logic beyond the skeleton created in earlier phases.

**Independent Test**: Run the full pipeline against issues of different types (Flow, Prompt Template, Agentforce) and verify type-appropriate scenarios and assertions.

### Implementation for User Story 4

- [x] T024 [US4] Review and enrich Flow modules — verify `.claude/skills/_qa-types/flow/{plan,data,run,eval}.md` cover: record-triggered vs scheduled vs autolaunched, decision element boundary conditions, loop element scenarios, subflow invocations, platform event triggers
- [x] T025 [US4] Review and enrich Prompt Template modules — verify `.claude/skills/_qa-types/prompt-template/{plan,data,run,eval}.md` cover: different template types (flex, field-gen, record-summary), merge field resolution, multi-language scenarios, token budget testing
- [x] T026 [US4] Review and enrich Agentforce modules — verify `.claude/skills/_qa-types/agentforce/{plan,data,run,eval}.md` cover: multi-topic agents, custom actions vs standard actions, grounding with Data Cloud, channel-specific behavior (web vs Slack vs API)

**Checkpoint**: All type modules fully enriched with domain-specific testing patterns.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, cost optimization, and workflow hardening

- [x] T027 [P] Update `scripts/install-sf-ai-tools.sh` if needed — verify it already symlinks `qa-plan/`, `qa-run/`, `qa-eval/`, `_qa-types/`, `_qa-shared/` (it should, since it symlinks all skills via wildcard)
- [x] T028 [P] Add `qa-plan` and `qa-execute` job failure notification steps to `.github/workflows/sf-ticket-to-pr.yml` — post comment on issue/PR when QA jobs fail (matching existing triage/execute failure notification pattern)
- [x] T029 [P] Document the QA pipeline in `docs/qa-pipeline.md` — architecture overview, how to add new type modules, cost expectations, troubleshooting guide
- [ ] T030 Run end-to-end validation — create a test issue with `@butler` mention, observe full pipeline (triage → execute + qa-plan → qa-execute), verify QA report on PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **US1 qa-plan (Phase 3)**: Depends on Phase 1 (needs type detection + registry modules)
- **US2 qa-execute (Phase 4)**: Depends on Phase 3 (needs qa-plan to exist for artifact flow)
- **US3 qa-eval (Phase 5)**: Depends on Phase 4 (needs qa-run to produce results)
- **US4 Type enrichment (Phase 6)**: Depends on Phases 3-5 (skeleton modules must exist)
- **Polish (Phase 7)**: Depends on Phases 3-5 (core pipeline must be functional)

### User Story Dependencies

- **US1 (P1)**: Independent after Phase 1 — can be tested standalone
- **US2 (P1)**: Depends on US1 (needs test plan artifact) — can be tested with a manually-created test plan
- **US3 (P2)**: Depends on US2 (needs test results) — can be tested with manually-created results
- **US4 (P2)**: Depends on US1-US3 (enriches existing modules) — can proceed in parallel with Phase 7

### Within Each Phase

- Tasks marked [P] can run in parallel (different files)
- Skill SKILL.md tasks depend on their type module tasks completing first
- Workflow YAML tasks depend on skill tasks completing first

### Parallel Opportunities

- T002, T003, T004, T005 (all shared modules) — parallel
- T006, T007, T008 (all plan type modules) — parallel
- T011-T016 (all data/run type modules) — parallel
- T019, T020, T021 (all eval type modules) — parallel
- T027, T028, T029 (polish tasks) — parallel

---

## Parallel Example: Phase 1 Setup

```bash
# Launch all shared modules together:
Task: "Create type detection module in .claude/skills/_qa-shared/type-detection.md"
Task: "Create type registry in .claude/skills/_qa-shared/type-registry.md"
Task: "Create SOQL assertions in .claude/skills/_qa-shared/sf-assertions.md"
Task: "Create PR reporting in .claude/skills/_qa-shared/sf-reporting.md"
```

## Parallel Example: Phase 4 Type Modules

```bash
# Launch all data/run modules together:
Task: "Create Flow data module in .claude/skills/_qa-types/flow/data.md"
Task: "Create Flow run module in .claude/skills/_qa-types/flow/run.md"
Task: "Create Prompt Template data module in .claude/skills/_qa-types/prompt-template/data.md"
Task: "Create Prompt Template run module in .claude/skills/_qa-types/prompt-template/run.md"
Task: "Create Agentforce data module in .claude/skills/_qa-types/agentforce/data.md"
Task: "Create Agentforce run module in .claude/skills/_qa-types/agentforce/run.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (shared modules)
2. Complete Phase 3: US1 — qa-plan skill + workflow job
3. **STOP and VALIDATE**: Trigger a test issue, verify qa-plan runs in parallel with execute, produces a test plan artifact
4. This alone is valuable — humans can manually review the test plan even without automated execution

### Incremental Delivery

1. Phase 1 → Shared modules ready
2. Phase 3 (US1) → qa-plan works → Can review test plans on issues
3. Phase 4 (US2) → qa-execute works → Automated data + e2e testing
4. Phase 5 (US3) → qa-eval works → Full reporting on PRs
5. Phase 6 (US4) → Type modules enriched → Higher-quality type-specific testing
6. Phase 7 → Polish → Production-ready

---

## Notes

- All skill files are Markdown — no compiled code, no dependencies beyond Claude Code and SF CLI
- The workflow YAML changes are purely additive — two new jobs appended, zero edits to triage or execute
- Type modules follow the same pattern: plan.md → data.md → run.md → eval.md — adding a new type means creating a new directory with these 4 files and registering it in type-registry.md
- Total: 30 tasks across 7 phases
