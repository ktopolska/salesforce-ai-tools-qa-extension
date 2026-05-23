# Contract: Test Plan Artifact

The test plan is the interface between `qa-plan` (producer) and `qa-execute` (consumer). Both are Claude Code agents reading/writing Markdown, so the contract is a structural convention rather than a formal schema.

## Artifact Identity

- **Name**: `test-plan`
- **Format**: Single Markdown file (`test-plan.md`)
- **Transport**: GitHub Actions artifact (upload in qa-plan, download in qa-execute)
- **Retention**: Default Actions artifact retention (90 days)

## Required Sections

### `## Metadata` (required)

| Field | Format | Example |
|-------|--------|---------|
| Issue | `#<number>` | `#42` |
| Detected types | Comma-separated list from: `flow`, `prompt-template`, `agentforce`, `apex` | `flow, apex` |
| Generated | ISO 8601 | `2026-05-23T14:30:00Z` |
| Scenario count | Integer | `14` |

### `## Data Test Scenarios` (required, may be empty)

Each scenario is an H3 (`### DT-NNN: <title>`) with these fields:
- **Type**: One of the detected types
- **Precondition**: Setup state needed (records to create, config to set)
- **Action**: The DML/API operation to perform
- **Expected**: The SOQL query and expected result
- **Requirement**: Direct quote or paraphrase from the issue body

### `## E2E Test Scenarios` (required, may be empty)

Each scenario is an H3 (`### ET-NNN: <title>`) with these fields:
- **Type**: One of the detected types
- **Navigation**: URL path or Lightning page to navigate to
- **Steps**: Numbered interaction steps
- **Expected**: What should be visible/true after the steps
- **Screenshot points**: Which steps to capture screenshots at
- **Requirement**: Direct quote or paraphrase from the issue body

## Versioning

No formal versioning. If the structure changes, both `qa-plan` and `qa-run` skills are updated together in the same PR.
