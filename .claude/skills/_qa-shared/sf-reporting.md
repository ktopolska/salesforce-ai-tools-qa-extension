# QA Reporting Module

Generates the QA report, posts it to the PR, commits screenshots, uploads videos, and manages labels. Used by qa-eval after test execution.

## QA Report Template

Post this as a PR comment via `gh pr comment <number> --repo <repo> --body-file /tmp/qa-report.md`:

```markdown
## QA Report — Issue #<number>

**Result**: <PASS or FINDINGS> | **Pass rate**: <passed>/<total> (<percent>%)

### Data Tests
| # | Scenario | Result | Details |
|---|----------|--------|---------|
| DT-001 | <title> | PASS/FAIL | <assertion detail or "all assertions passed"> |

### E2E Tests
| # | Scenario | Result | Screenshot | Details |
|---|----------|--------|------------|---------|
| ET-001 | <title> | PASS/FAIL | [view](<link>) | <detail> |

### Failures
_(omit this section if all tests passed)_

#### Root Cause 1: <category>
**Severity**: Critical/High/Medium/Low
**Scenarios**: DT-002, ET-003
**Summary**: <what went wrong and likely why>
**Evidence**: <screenshot links, SOQL results>
```

## Screenshot Management

Commit screenshots to the PR branch:

```bash
mkdir -p .verification/qa/
cp /tmp/qa-screenshots/*.png .verification/qa/
git add .verification/qa/
git commit -m "qa: add test screenshots for issue #<number>"
git push
```

Reference screenshots in the report using relative paths:
`[view](.verification/qa/<filename>.png)`

## Video Upload

Videos are too large for git. Upload as GitHub Actions artifacts within the workflow step:

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: qa-videos
    path: /tmp/qa-videos/
    retention-days: 30
```

Link in the report: "Videos available in the [Actions artifacts](<run-url>)."

## Label Management

If any test failed, add the `qa-findings` label:

```bash
gh pr edit <number> --repo <repo> --add-label "qa-findings"
```

If all tests passed and the label exists from a previous run, remove it:

```bash
gh pr edit <number> --repo <repo> --remove-label "qa-findings" 2>/dev/null || true
```

## Cost Reporting

After qa-eval completes, the workflow runs `report-ai-cost.sh` (same script used by triage and execute) to append cost data to the issue thread.
