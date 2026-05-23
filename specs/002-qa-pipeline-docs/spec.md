# Feature Specification: QA Pipeline Documentation

**Feature Branch**: `002-qa-pipeline-docs`

**Created**: 2026-05-23

**Status**: Draft

**Input**: User description: "Create a documentation page at docs/qa-pipeline.md describing the parallel QA track added to the sf-ticket-to-pr workflow."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Developer Understands the QA Pipeline (Priority: P1)

A developer new to the project opens `docs/qa-pipeline.md` and within 5 minutes understands: what the QA track does, how it fits into the existing workflow, what each job produces, and where the QA report appears.

**Why this priority**: Without understanding the pipeline, developers cannot debug failures, review QA reports, or contribute improvements. This is the core value of the documentation.

**Independent Test**: Show the document to a developer unfamiliar with the project and ask them to explain the pipeline flow. They should be able to describe the 4-job sequence and what each produces.

**Acceptance Scenarios**:

1. **Given** a developer opens docs/qa-pipeline.md, **When** they read the pipeline overview section, **Then** they can identify the 4 jobs (triage, execute, qa-plan, qa-execute) and their dependency relationships.
2. **Given** a developer reads the pipeline diagram, **When** they trace the flow, **Then** they understand that qa-plan runs in parallel with execute and qa-execute waits for both.
3. **Given** a developer reads the skills section, **When** they look for how test scenarios are generated, **Then** they find the qa-plan skill description and understand it reads issue requirements without needing an org.

---

### User Story 2 - Developer Extends the Pipeline with a New Type (Priority: P2)

A developer wants to add QA support for a new Salesforce metadata type (e.g., Apex). They open the documentation, find the "Adding a new type" section, and follow the step-by-step checklist to create the required module files.

**Why this priority**: The type module system is designed to be extensible. Without clear instructions, developers will either skip it or get the structure wrong.

**Independent Test**: Follow the "Adding a new type" checklist for a hypothetical type and verify the instructions reference the correct file paths and registry.

**Acceptance Scenarios**:

1. **Given** a developer reads the "Adding a new type" section, **When** they follow the steps, **Then** they know to create 4 files (plan.md, data.md, run.md, eval.md) in a new `_qa-types/<type>/` directory.
2. **Given** a developer follows the checklist, **When** they complete all steps, **Then** they have also updated the type-detection and type-registry shared modules.

---

### User Story 3 - Developer Debugs a QA Failure (Priority: P2)

A developer sees a failed qa-execute job in GitHub Actions. They open the documentation to understand what artifacts to check, how the QA report is structured, and what the failure categories mean.

**Why this priority**: QA failures are the pipeline's primary output. If developers can't interpret them, the pipeline has no value.

**Independent Test**: Present a sample QA report with failures and ask the developer to identify the root cause category and severity using the documentation.

**Acceptance Scenarios**:

1. **Given** a developer reads the artifacts section, **When** they look for test evidence, **Then** they know to check the `qa-screenshots` artifact and the QA report comment on the PR/issue.
2. **Given** a developer reads the QA report format section, **When** they see a failure grouped by root cause, **Then** they understand the severity classification and fix suggestions.

---

### Edge Cases

- What if the document references file paths that have been moved or renamed since it was written?
- How does the document stay current as the pipeline evolves?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Document MUST include a visual pipeline diagram showing all 4 jobs and their dependencies.
- **FR-002**: Document MUST describe each job's purpose, inputs, outputs, and trigger conditions.
- **FR-003**: Document MUST list all 3 skills (qa-plan, qa-run, qa-eval) with their roles.
- **FR-004**: Document MUST describe the 3 supported type modules (Flow, Prompt Template, Agentforce) and what each covers.
- **FR-005**: Document MUST list the shared modules in `_qa-shared/` and their purposes.
- **FR-006**: Document MUST describe all artifacts produced (test-plan, qa-screenshots) and where to find them.
- **FR-007**: Document MUST show the QA report format with an example.
- **FR-008**: Document MUST include a step-by-step checklist for adding a new metadata type.
- **FR-009**: Document MUST describe configuration options (max-turns, model selection) and where to change them.
- **FR-010**: Document MUST be a single Markdown file at `docs/qa-pipeline.md`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer new to the project can describe the pipeline's 4-job flow after reading the document for 5 minutes.
- **SC-002**: The "Adding a new type" section contains a complete checklist that a developer can follow without referencing any other file.
- **SC-003**: The document covers 100% of the skills, type modules, and shared modules that exist in the codebase.
- **SC-004**: The QA report format section includes a concrete example matching the actual report structure.

## Assumptions

- The document describes the pipeline as currently implemented — it is not a forward-looking design document.
- File paths in the document reference the current repository structure and may need updating if files move.
- The target audience has basic familiarity with GitHub Actions workflows but may not know the QA pipeline specifics.
- The document uses Mermaid for diagrams, matching the existing README style.
