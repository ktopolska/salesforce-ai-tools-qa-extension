# QA Run — Test Execution (Data + E2E)

Execute a test plan against a Salesforce scratch org. Runs two phases: fast data tests via SOQL/API (Phase 1), then e2e tests via Playwright Node.js scripts (Phase 2). Skips Phase 2 if Phase 1 has critical failures.

## Inputs

You will receive:
- **Test plan**: A file at `/tmp/test-plan.md`
- **Scratch org alias**: The target org alias (e.g., `pr-42`)
- **Frontdoor URL**: A pre-generated login URL for the scratch org
- **Instance URL**: The org's instance URL (e.g., `https://example.scratch.my.salesforce.com`)
- **Repo**: The GitHub repository for reporting context

## Execution Steps

### 1. Parse the Test Plan

Read `/tmp/test-plan.md` and extract:
- **Metadata**: Issue number, detected types, scenario count
- **Data test scenarios (DT-NNN)**: Each with type, precondition, action, expected
- **E2E test scenarios (ET-NNN)**: Each with type, navigation, steps, expected, screenshot points

Read `~/.claude/skills/_qa-shared/type-registry.md` to resolve type module paths.

### 2. Phase 1 — Data Tests

For each DT-NNN scenario:

1. **Load type module**: Read `~/.claude/skills/_qa-types/<type>/data.md` for data creation patterns and `~/.claude/skills/_qa-types/<type>/run.md` for assertion patterns
2. **Setup**: Create test data per the scenario's precondition using patterns from `data.md`
3. **Execute**: Perform the action (DML operation, API call) per the scenario
4. **Assert**: Run the SOQL query or check the API response per the expected outcome. Use patterns from `~/.claude/skills/_qa-shared/sf-assertions.md`
5. **Record result**: Store PASS/FAIL with details for each scenario
6. **Write results incrementally**: After each scenario completes, write the full results JSON to `/tmp/qa-results.json` (overwrite). This ensures partial results survive if execution is interrupted.

#### Efficiency: Batch Operations

- **Group record creation**: Create all test records for related scenarios before running assertions. For example, create all Opportunity records first (in sequential `sf data create record` commands or a single Apex script), then run all SOQL assertions.
- **Combine SOQL fields**: When multiple scenarios check different fields on the same record, query once with all needed fields in the SELECT clause rather than one query per field.
- **One setup, many assertions**: Write a single bash script that creates all Phase 1 test data, run it once, then run assertions against the created records.
- **Target pace**: ~2-3 turns per data test scenario (batch create + batch assert + record results).

**Critical failure check**: After all data tests, if more than 50% of scenarios failed, flag Phase 2 as skipped:
- Record: "Phase 2 (E2E) skipped — too many data test failures indicate fundamental issues"
- Proceed directly to output

### 3. Phase 2 — E2E Tests (Playwright Node.js Scripts)

**Prerequisites**: Phase 1 did not hit the critical failure threshold. Frontdoor URL is available.

Write ONE `.mjs` script for ALL E2E scenarios and run it with `node`. The script must:

1. **Launch Chromium**: `import { chromium } from 'playwright';` with `executablePath: '/usr/bin/chromium'` and `args: ['--no-sandbox', '--disable-dev-shm-usage']`
2. **Authenticate once**: Navigate to the frontdoor URL. Wait for the page to load fully.
3. **Run all scenarios sequentially** in the same browser session:
   - Navigate directly to record pages: `${instanceUrl}/lightning/r/<Object>/<Id>/view`
   - Reuse record IDs created during Phase 1 data tests
   - Wrap each scenario in try/catch so failures don't abort remaining scenarios
   - On failure, capture a diagnostic screenshot before continuing
4. **Capture screenshots**: Save to `/tmp/qa-screenshots/<scenario-id>.png`
5. **Close browser**: After all scenarios complete

Run `mkdir -p /tmp/qa-screenshots` before executing the script.

**Wait strategies**: Use `page.waitForFunction()` checking for expected text or DOM elements. Do NOT use `waitForLoadState('networkidle')` — Lightning pages never fully reach network idle. Use `page.getByRole()` and `page.getByText()` for element selection — NOT CSS selectors.

Read `~/.claude/skills/_qa-types/<type>/run.md` for type-specific Playwright patterns (login, navigation, wait-for-load, assertions).

If the frontdoor URL is empty, skip Phase 2 and note "frontdoor URL not available" in results.

### 4. Collect Results

For each scenario (DT and ET), collect:

```
Scenario: <ID>
Title: <title>
Type: <type>
Phase: data | e2e
Result: PASS | FAIL
Details: <assertion result or error message>
Screenshot: <path if applicable>
```

### 5. Output

Write results to `/tmp/qa-results.json` after each scenario completes (overwrite the file each time so it always contains valid JSON with all completed scenarios):

```json
{
  "issue_number": 42,
  "detected_types": ["flow"],
  "scenarios": [
    {
      "id": "DT-001",
      "title": "...",
      "type": "flow",
      "phase": "data",
      "result": "PASS",
      "details": "...",
      "screenshot": null
    }
  ],
  "phase2_skipped": false,
  "phase2_skip_reason": null,
  "total": 10,
  "passed": 8,
  "failed": 2
}
```

## Key Principles

- **Data first**: Always run Phase 1 before Phase 2. Data tests are 100x faster and catch the same logic bugs.
- **Fail fast**: If data tests show fundamental problems (>50% failure), don't waste time on Playwright.
- **Single browser session**: Launch one Chromium instance, authenticate once, run all E2E scenarios sequentially. Direct record URLs instead of UI navigation.
- **Evidence**: Capture screenshots at every assertion point and on every failure.
- **Incremental results**: Write results after each scenario so partial results survive interruptions.
- **No code changes**: This skill tests the deployed code. It does not modify source files.
- **Graceful degradation**: If Playwright login fails, if SOQL errors out, if the org is unresponsive — log the failure, don't crash.
