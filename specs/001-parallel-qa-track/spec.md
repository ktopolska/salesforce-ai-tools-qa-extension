# Feature Specification: Parallel QA Track for sf-ticket-to-pr

**Feature Branch**: `001-parallel-qa-track`

**Created**: 2026-05-23

**Status**: Draft

**Input**: User description: "Add a parallel QA track to the sf-ticket-to-pr workflow that runs independently alongside the existing dev pipeline. Includes qa-plan (requirements-driven test generation), qa-execute (data + e2e testing), and qa-eval (PR reporting)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Requirements-Driven Test Plan Generation (Priority: P1)

When a GitHub issue is triaged and approved for development, the QA track automatically reads the issue requirements and the triage plan comment, then generates a comprehensive test plan with numbered scenarios and expected outcomes — all without needing a scratch org.

**Why this priority**: The test plan is the foundation for all downstream testing. Without it, qa-execute has nothing to run. It also enables requirements-vs-implementation gap detection — the core value proposition of an independent QA track.

**Independent Test**: Can be fully tested by creating a sample GitHub issue with requirements text, running qa-plan, and verifying it produces a test plan artifact with correctly inferred types and scenarios.

**Acceptance Scenarios**:

1. **Given** a triaged issue with clear requirements (e.g., "create a record-triggered Flow that sends an email when Opportunity Stage changes to Closed Won"), **When** qa-plan runs, **Then** it produces a test plan artifact containing scenarios that cover the stated behavior, boundary conditions, and expected outcomes.
2. **Given** a triaged issue mentioning multiple Salesforce types (e.g., Flow + Prompt Template), **When** qa-plan runs, **Then** it correctly identifies all types from the text and loads the appropriate type-specific planning modules for each.
3. **Given** a triaged issue with ambiguous requirements, **When** qa-plan runs, **Then** it generates scenarios based on reasonable interpretations and flags ambiguities in the test plan for human review.
4. **Given** triage outputs `proceed=true`, **When** the workflow starts, **Then** qa-plan and the dev execute job begin in parallel (not sequentially).

---

### User Story 2 - Automated Data and E2E Test Execution (Priority: P1)

After both the dev track deploys code and the QA track generates a test plan, qa-execute restores the scratch org and runs two layers of tests: fast data tests via SOQL/API, then slower e2e tests via Playwright with video recording and screenshots.

**Why this priority**: This is the core testing engine. Without execution, the test plan is just a document. Data tests catch logic and automation bugs quickly; e2e tests catch UI and integration issues with visual evidence.

**Independent Test**: Can be tested by providing a pre-built test plan artifact and a scratch org with deployed code, then running qa-execute and verifying it produces pass/fail results with screenshots and video.

**Acceptance Scenarios**:

1. **Given** a deployed scratch org and a downloaded test plan with data test scenarios, **When** qa-execute runs Phase 1, **Then** it creates test data via CLI/API, triggers automations via DML, and asserts outcomes via SOQL queries.
2. **Given** a deployed scratch org and a test plan with e2e scenarios, **When** qa-execute runs Phase 2, **Then** it logs into the scratch org via frontdoor URL, navigates through each scenario in Playwright, records video of the full journey, and captures screenshots at assertion points.
3. **Given** qa-execute completes both phases, **When** Phase 3 (evaluate) runs, **Then** it compares actual vs expected for every scenario, groups failures by root cause, and classifies severity.
4. **Given** the dev execute job has not finished yet, **When** qa-plan completes, **Then** qa-execute waits until both execute and qa-plan have succeeded before starting.

---

### User Story 3 - QA Report on Pull Request (Priority: P2)

After test execution and evaluation, qa-execute posts a structured QA report as a comment on the PR, commits screenshots to the PR branch, uploads videos as GitHub Actions artifacts, and labels the PR if failures are found.

**Why this priority**: Reporting makes the QA results actionable. Without visible results on the PR, the testing has no impact on the review process.

**Independent Test**: Can be tested by providing evaluation results (pass/fail data, screenshots, video files) and a PR number, then running the reporting phase and verifying the PR comment, committed screenshots, uploaded artifacts, and labels.

**Acceptance Scenarios**:

1. **Given** evaluation results with all scenarios passing, **When** Phase 4 (report) runs, **Then** it posts a QA report comment on the PR showing 100% pass rate and commits screenshots to `.verification/qa/` on the PR branch.
2. **Given** evaluation results with failures, **When** Phase 4 runs, **Then** it posts a QA report with failure details (bug summaries, root causes, severity), commits screenshots, uploads video artifacts, and labels the PR with `qa-findings`.
3. **Given** e2e test videos, **When** reporting runs, **Then** videos are uploaded as GitHub Actions artifacts (not committed to git) to avoid repository bloat.

---

### User Story 4 - Type-Specific Testing Modules (Priority: P2)

The QA track uses polymorphic type modules (`_qa-types/`) so that each Salesforce metadata type (Flow, Prompt Template, Agentforce) gets specialized planning, data creation, execution, and evaluation logic.

**Why this priority**: Generic testing misses type-specific nuances. A Flow needs DML triggers and SOQL assertions; a Prompt Template needs API invocations and output quality checks; an Agentforce agent needs multi-turn conversation testing. Type modules encode this domain expertise.

**Independent Test**: Can be tested by running qa-plan and qa-execute against issues of different types and verifying each produces type-appropriate scenarios and assertions.

**Acceptance Scenarios**:

1. **Given** an issue about a record-triggered Flow, **When** qa-plan loads the Flow type module, **Then** the test plan includes DML-based trigger patterns, boundary condition detection, and SOQL assertion scenarios.
2. **Given** an issue about a Prompt Template, **When** qa-plan loads the Prompt Template type module, **Then** the test plan includes API invocation scenarios and output quality evaluation criteria.
3. **Given** an issue about an Agentforce agent, **When** qa-plan loads the Agentforce type module, **Then** the test plan includes multi-turn conversation scenarios and session tracing assertions.

---

### Edge Cases

- What happens when type detection from issue text is ambiguous (e.g., issue mentions both "Flow" and "Apex trigger" but only means one)?
- How does the system handle qa-execute when the scratch org cache is missing or expired?
- What happens when the dev execute job fails but qa-plan succeeds — does qa-execute still run?
- How does the system behave when Playwright cannot log into the scratch org (e.g., frontdoor URL expired)?
- What happens when the test plan artifact exceeds GitHub Actions artifact size limits?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST run qa-plan in parallel with the dev execute job after triage outputs `proceed=true`, with no dependency between them.
- **FR-002**: System MUST generate test scenarios from the GitHub issue body and triage plan comment, not from the deployed implementation.
- **FR-003**: System MUST infer Salesforce metadata types (Flow, Prompt Template, Agentforce) from issue text without requiring org access during planning. Apex detection is supported but deferred to a future iteration for type-specific modules.
- **FR-004**: System MUST load type-specific planning modules from `_qa-types/<type>/plan.md` based on detected types.
- **FR-005**: System MUST upload the full test plan as a GitHub Actions artifact for downstream consumption by qa-execute.
- **FR-006**: System MUST wait for both the dev execute job and qa-plan to succeed before starting qa-execute.
- **FR-007**: System MUST restore the scratch org from cache (same cache the dev execute job used) before running tests.
- **FR-008**: System MUST execute data tests (Phase 1) before e2e tests (Phase 2) to catch logic bugs cheaply before spending time on browser tests.
- **FR-009**: System MUST create test data via `sf data create record` or bulk import during Phase 1.
- **FR-010**: System MUST assert outcomes via SOQL queries during Phase 1 data testing.
- **FR-011**: System MUST log into the scratch org via frontdoor URL for Playwright e2e testing.
- **FR-012**: System MUST record video of the full e2e journey and capture screenshots at key assertion points.
- **FR-013**: System MUST compare actual vs expected outcomes, group failures by root cause, and classify severity during evaluation (Phase 3).
- **FR-014**: System MUST post a structured QA report as a PR comment with pass rate, failure details, and bug summaries.
- **FR-015**: System MUST commit screenshots to `.verification/qa/` on the PR branch.
- **FR-016**: System MUST upload videos as GitHub Actions artifacts (not git-committed).
- **FR-017**: System MUST label the PR with `qa-findings` when test failures are found.
- **FR-018**: System MUST post a summary comment on the issue after generating the test plan (e.g., "QA plan: 14 test scenarios covering...").

### Key Entities

- **Test Plan**: A structured document containing numbered test scenarios with expected outcomes, organized by type and phase (data vs e2e). Generated from requirements, consumed by qa-execute.
- **Test Scenario**: An individual test case with preconditions, actions, and expected outcomes. Tagged with type (Flow, Prompt Template, etc.) and phase (data or e2e).
- **QA Report**: A structured summary posted to the PR showing pass/fail rates, failure details grouped by root cause, severity classifications, and links to evidence (screenshots, videos).
- **Type Module**: A set of type-specific skill files (plan.md, data.md, run.md, eval.md) that encode domain expertise for a particular Salesforce metadata type.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: QA track completes without adding more than 5 minutes to the overall pipeline wall-clock time (qa-plan runs in parallel with dev, so only qa-execute adds sequential time).
- **SC-002**: Test plans cover at least 80% of the acceptance criteria stated in the issue requirements.
- **SC-003**: Data tests (Phase 1) complete within 30 seconds for a typical issue (5-10 scenarios).
- **SC-004**: E2E tests (Phase 2) complete within 5 minutes for a typical issue (3-5 browser scenarios).
- **SC-005**: QA report is posted on the PR within 2 minutes of test completion.
- **SC-006**: Type detection from issue text achieves at least 90% accuracy across Flow, Prompt Template, and Agentforce issue types.
- **SC-007**: Zero changes required to the existing triage or execute jobs — QA track is purely additive.
- **SC-008**: QA findings catch at least one category of bug that the dev track's built-in verification (Apex tests, code analyzer) does not cover (e.g., UI rendering, requirements mismatch, boundary conditions).

## Assumptions

- The existing scratch org caching mechanism used by the dev execute job is reliable and qa-execute can restore from the same cache key.
- GitHub Actions artifact passing between jobs (upload in qa-plan, download in qa-execute) works reliably within the same workflow run.
- Text-based type detection from issue body and triage comments is sufficient for the initial version; org-based detection can be added later if accuracy is insufficient.
- The `sf-ticket-to-pr` workflow already has a working triage job that outputs `proceed=true` and a working execute job that deploys to a scratch org.
- Playwright and the Salesforce CLI are available or installable on the GitHub Actions runner used by qa-execute.
- QA findings will initially be report-only (posted on PR for human review). Auto-fix and re-trigger-dev modes are deferred to a future iteration.
- The test plan summary comment on the issue (FR-018) is always posted in v1. If noise becomes a concern, a configuration toggle can be added later.
- Cost budget constraints (max-turns, model selection) will be defined during implementation planning, not in this spec.
