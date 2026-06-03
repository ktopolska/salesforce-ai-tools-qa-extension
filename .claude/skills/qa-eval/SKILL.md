# QA Eval — Results Evaluation + Reporting

Evaluate test results from qa-run, classify failures by root cause and severity, generate a QA report, post it on the PR or issue, and manage labels.

## Inputs

You will receive:
- Test results at `/tmp/qa-results.json` (or passed in conversation context)
- Screenshots at `/tmp/qa-screenshots/`
- The issue/PR number and repository
- The Actions run URL for artifact links

## Execution Steps

### 1. Load Results

Read `/tmp/qa-results.json`. Extract:
- Total scenarios, passed count, failed count, unresolved count
- Per-scenario details (ID, title, type, phase, result, details)
- For each scenario: `fix_attempted` (boolean) and `fix_details` (string, what was tried) if present
- Whether Phase 2 was skipped and why

Valid result statuses: **PASS**, **FAIL**, **UNRESOLVED** (check failed, fix was attempted, still fails).

**If the file does not exist or is empty**: Post a comment on the PR/issue noting "QA tests could not complete — no results available." Then stop.

**If results are partial** (fewer scenarios than expected, or Phase 2 incomplete): Include all available results and note which phases were incomplete.

### 2. Classify Failures

For each failed or unresolved scenario:

1. **Identify the type**: Read `~/.claude/skills/_qa-shared/type-registry.md` to locate the eval module
2. **Load eval module**: Read `~/.claude/skills/_qa-types/<type>/eval.md`
3. **Match failure pattern**: Compare the failure details against the known failure categories in the eval module
4. **Assign root cause**: Pick the best-matching category
5. **Assign severity**: Use the default severity from the eval module, adjusted for context:
   - Promote to Critical if the failure blocks core functionality
   - Demote to Low if it's cosmetic or edge-case-only
6. **Classify root cause type**: Determine if the failure is **code-level** (wrong logic, missing field, broken automation) or **environment** (org timeout, session expired, Playwright flakiness, network error)
7. **For UNRESOLVED scenarios**: Note what fix was attempted (`fix_details`) and why it did not resolve the issue. This context is critical for the failure group summary — it tells the human reviewer what has already been tried

### 3. Group Failures

Group failures by root cause category. For each group:
- List affected scenario IDs
- Summarize the common pattern
- Link to evidence (SOQL results, screenshot references)
- Provide the fix suggestion from the eval module

### 4. Generate QA Report

Read `~/.claude/skills/_qa-shared/sf-reporting.md` for the report template.

Write the report to `/tmp/qa-report.md` following the template structure:
- Header with pass/fail result and pass rate
- Data Tests table (include a "Fix Attempted" column showing what was tried for FAIL/UNRESOLVED scenarios)
- E2E Tests table with artifact link for screenshots (same "Fix Attempted" column)
- Failures section (grouped by root cause, with severity and fix suggestions). For UNRESOLVED scenarios, include what fix was attempted and the outcome under the group summary.

**Screenshot links**: Do NOT use relative paths. Instead:
- Add in the E2E Tests section header: `Screenshots available in the [Actions artifacts](<run-url>)`
- In individual E2E test rows, use `see artifacts` in the Screenshot column

### 5. Post Report

Find the PR for this issue:

```bash
PR_NUMBER=$(gh pr list --repo $REPO --search "head:fix/issue-$ISSUE_NUMBER" --json number --jq '.[0].number')
```

If a PR exists, post there:
```bash
gh pr comment $PR_NUMBER --repo $REPO --body-file /tmp/qa-report.md
```

If no PR found, post on the issue:
```bash
gh issue comment $ISSUE_NUMBER --repo $REPO --body-file /tmp/qa-report.md
```

### 6. Manage Labels

**`qa-findings` label** — applies when any test failed (FAIL or UNRESOLVED):
```bash
gh pr edit $PR_NUMBER --repo $REPO --add-label "qa-findings"
```

If all tests passed and `qa-findings` label exists from a prior run:
```bash
gh pr edit $PR_NUMBER --repo $REPO --remove-label "qa-findings" 2>/dev/null || true
```

**`qa-fix-needed` label** — applies when any failure has a **code-level** root cause (not environment/flakiness):
```bash
gh issue edit $ISSUE_NUMBER --repo $REPO --add-label "qa-fix-needed"
```

Do NOT apply `qa-fix-needed` if all failures are environment issues (org timeout, session expired, Playwright flakiness). Only apply when failures indicate actual bugs in the deployed code.

If all tests passed and `qa-fix-needed` label exists from a prior run:
```bash
gh issue edit $ISSUE_NUMBER --repo $REPO --remove-label "qa-fix-needed" 2>/dev/null || true
```

### 7. Summary

Output a brief summary:
- "QA Report posted on PR #<number>: <passed>/<total> scenarios passed (<percent>%)"
- If failures: "Found <n> issues (<X> failed, <Y> unresolved after fix attempts) across <categories> categories. Highest severity: <level>."
- If all passed: "All scenarios passed. No findings."

## Key Principles

- **Root cause, not symptoms**: Group failures by WHY they failed, not by which test failed. Two tests failing for the same Flow entry condition bug is one finding, not two.
- **Actionable suggestions**: Every failure group includes a fix suggestion from the type eval module.
- **Evidence-based**: Link SOQL results and screenshots to specific failures.
- **Code vs environment**: Distinguish code-level bugs (label `qa-fix-needed`) from environment flakiness (label `qa-findings` only). UNRESOLVED scenarios are code-level by definition — a fix was attempted and failed.
- **Fix transparency**: For UNRESOLVED scenarios, always surface what was tried so human reviewers do not repeat the same approach.
- **Non-blocking**: QA findings are informational. The report does not block the PR — humans decide whether to act on findings.
