# QA Reporting Module

Generates the QA report, posts it to the PR or issue, and manages labels. Used by qa-eval after test execution.

## QA Report Template

Post this as a comment via `gh pr comment` or `gh issue comment`:

```markdown
## QA Report — Issue #<number>

**Result**: <PASS or FINDINGS> | **Pass rate**: <passed>/<total> (<percent>%)

### Data Tests
| # | Scenario | Result | Fix Attempted | Details |
|---|----------|--------|---------------|---------|
| DT-001 | <title> | PASS/FAIL/UNRESOLVED | Yes/No | <assertion detail or "all assertions passed"> |

Result statuses:
- **PASS** — check succeeded
- **FAIL** — check failed, no code-level fix was possible
- **UNRESOLVED** — check failed, a fix was attempted but the check still fails after re-deploy

### E2E Tests

Screenshots available in the [Actions artifacts](<run-url>)

| # | Scenario | Result | Screenshot | Details |
|---|----------|--------|------------|---------|
| ET-001 | <title> | PASS/FAIL | see artifacts | <detail> |

### Failures
_(omit this section if all tests passed)_

Group failures into two subsections:

#### Failed (no fix attempted)
_(checks that failed but no code-level fix was applicable)_

##### Root Cause 1: <category>
**Severity**: Critical/High/Medium/Low
**Scenarios**: DT-002, ET-003
**Summary**: <what went wrong and likely why>
**Evidence**: <SOQL results, screenshot references>

#### Unresolved (fix attempted)
_(checks that failed, a fix was attempted, but the check still fails after re-deploy)_

##### Root Cause 1: <category>
**Severity**: Critical/High/Medium/Low
**Scenarios**: DT-004
**Summary**: <what went wrong, what fix was attempted, why it still fails>
**Evidence**: <SOQL results, screenshot references>
```

## Screenshot Management

Screenshots are uploaded as GitHub Actions artifacts by the workflow. They are accessible from the Actions run page for 30 days.

In the report, link to screenshots using the artifact page URL:
- E2E section header: `Screenshots available in the [Actions artifacts](<run-url>)`
- Individual E2E rows: use `see artifacts` in the Screenshot column

Do NOT use relative paths like `[view](.verification/qa/<filename>.png)` — they do not work in issue comments.

## Label Management

### `qa-findings` label

If any test failed, add the `qa-findings` label:

```bash
gh pr edit <number> --repo <repo> --add-label "qa-findings"
```

If all tests passed and the label exists from a previous run, remove it:

```bash
gh pr edit <number> --repo <repo> --remove-label "qa-findings" 2>/dev/null || true
```

### `qa-fix-needed` label

If any failure has a **code-level** root cause (wrong logic, missing field, broken automation — NOT environment issues like org timeout, session expired, or Playwright flakiness):

```bash
gh issue edit <number> --repo <repo> --add-label "qa-fix-needed"
```

If all tests passed and the label exists from a previous run, remove it:

```bash
gh issue edit <number> --repo <repo> --remove-label "qa-fix-needed" 2>/dev/null || true
```

## Cost Reporting

After qa-eval completes, the workflow runs `report-ai-cost.sh` (same script used by triage and execute) to append cost data to the issue thread.
