# QA Eval — Results Evaluation + PR Reporting

Evaluate test results from qa-run, classify failures by root cause and severity, generate a QA report, post it on the PR, commit screenshots, upload videos, and label the PR.

## Inputs

You will receive:
- Test results from qa-run (either at `/tmp/qa-results.json` or passed in conversation context)
- Screenshots at `/tmp/qa-screenshots/`
- Videos at `/tmp/qa-videos/`
- The issue/PR number and repository

## Execution Steps

### 1. Load Results

Read the test results. Extract:
- Total scenarios, passed count, failed count
- Per-scenario details (ID, title, type, phase, result, details)
- Whether Phase 2 was skipped and why

### 2. Classify Failures

For each failed scenario:

1. **Identify the type**: Read `~/.claude/skills/_qa-shared/type-registry.md` to locate the eval module
2. **Load eval module**: Read `~/.claude/skills/_qa-types/<type>/eval.md`
3. **Match failure pattern**: Compare the failure details against the known failure categories in the eval module
4. **Assign root cause**: Pick the best-matching category
5. **Assign severity**: Use the default severity from the eval module, adjusted for context:
   - Promote to Critical if the failure blocks core functionality
   - Demote to Low if it's cosmetic or edge-case-only

### 3. Group Failures

Group failures by root cause category. For each group:
- List affected scenario IDs
- Summarize the common pattern
- Link to evidence (screenshots, SOQL results)
- Provide the fix suggestion from the eval module

### 4. Generate QA Report

Read `~/.claude/skills/_qa-shared/sf-reporting.md` for the report template.

Write the report to `/tmp/qa-report.md` following the template structure:
- Header with pass/fail result and pass rate
- Data Tests table
- E2E Tests table (with screenshot links)
- Failures section (grouped by root cause, with severity and fix suggestions)

### 5. Post Report on PR

Find the PR for this issue:

```bash
PR_NUMBER=$(gh pr list --repo $REPO --search "head:fix/issue-$ISSUE_NUMBER" --json number --jq '.[0].number')
```

If no PR found, try the branch name from the workflow context.

Post the report:

```bash
gh pr comment $PR_NUMBER --repo $REPO --body-file /tmp/qa-report.md
```

### 6. Commit Screenshots

```bash
mkdir -p .verification/qa/
cp /tmp/qa-screenshots/*.png .verification/qa/ 2>/dev/null || true

if [ -n "$(ls .verification/qa/ 2>/dev/null)" ]; then
  git add .verification/qa/
  git commit -m "qa: add test screenshots for issue #$ISSUE_NUMBER"
  git push
fi
```

### 7. Manage Labels

If any failures exist:
```bash
gh pr edit $PR_NUMBER --repo $REPO --add-label "qa-findings"
```

If all tests passed and `qa-findings` label exists from a prior run:
```bash
gh pr edit $PR_NUMBER --repo $REPO --remove-label "qa-findings" 2>/dev/null || true
```

### 8. Summary

Output a brief summary:
- "QA Report posted on PR #<number>: <passed>/<total> scenarios passed (<percent>%)"
- If failures: "Found <n> issues across <categories> categories. Highest severity: <level>."
- If all passed: "All scenarios passed. No findings."

## Key Principles

- **Root cause, not symptoms**: Group failures by WHY they failed, not by which test failed. Two tests failing for the same Flow entry condition bug is one finding, not two.
- **Actionable suggestions**: Every failure group includes a fix suggestion from the type eval module.
- **Evidence-based**: Link screenshots and SOQL results to specific failures.
- **Non-blocking**: QA findings are informational. The report does not block the PR — humans decide whether to act on findings.
