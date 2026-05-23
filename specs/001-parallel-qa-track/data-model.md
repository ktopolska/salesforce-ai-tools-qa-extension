# Data Model: Parallel QA Track

This feature has no persistent data model (no database tables, custom objects, or stored state). All data flows through ephemeral artifacts within a single GitHub Actions workflow run.

## Artifact Flow

```
Issue Body + Triage Comment
        │
        ▼
┌─────────────────┐
│   Test Plan     │  GitHub Actions artifact: "test-plan"
│   (Markdown)    │  Produced by: qa-plan
│                 │  Consumed by: qa-execute
│  - metadata     │
│  - data scenarios│
│  - e2e scenarios│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Test Results   │  In-memory during qa-execute
│                 │
│  - pass/fail    │
│  - screenshots  │  → committed to .verification/qa/ on PR branch
│  - videos       │  → uploaded as Actions artifact "qa-videos"
│  - root causes  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   QA Report     │  Posted as PR comment via gh CLI
│   (Markdown)    │
│  - summary      │
│  - data results │
│  - e2e results  │
│  - failures     │
└─────────────────┘
```

## Test Plan Structure

```markdown
# Test Plan: Issue #<number>
## Metadata
- Issue: #<number>
- Detected types: [flow, prompt-template, agentforce]
- Generated: <timestamp>
- Scenario count: <N>

## Data Test Scenarios
### DT-001: <title>
- **Type**: <detected-type>
- **Precondition**: <setup required>
- **Action**: <DML operation or API call>
- **Expected**: <SOQL assertion or API response>
- **Requirement**: <traces back to issue text>

## E2E Test Scenarios
### ET-001: <title>
- **Type**: <detected-type>
- **Navigation**: <page/component to navigate to>
- **Steps**: <interaction sequence>
- **Expected**: <visual/functional assertion>
- **Screenshot points**: <when to capture>
- **Requirement**: <traces back to issue text>
```

## QA Report Structure

```markdown
## QA Report — Issue #<number>

**Result**: <PASS ✅ | FINDINGS ⚠️> | **Pass rate**: <N/M> (<percent>%)

### Data Tests
| # | Scenario | Result | Details |
|---|----------|--------|---------|
| DT-001 | <title> | ✅/❌ | <assertion detail> |

### E2E Tests
| # | Scenario | Result | Screenshot | Details |
|---|----------|--------|------------|---------|
| ET-001 | <title> | ✅/❌ | [view](link) | <detail> |

### Failures (if any)
#### Root Cause 1: <category>
**Severity**: Critical/High/Medium/Low
**Scenarios**: DT-002, ET-003
**Summary**: <what went wrong and likely why>
**Evidence**: <screenshot links, SOQL results>
```
