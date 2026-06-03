# QA Check — Materialize, Run, and Fix

Materialize abstract test scenarios into concrete checks, execute them against a Salesforce scratch org, and fix code-level failures. Runs two phases: fast data checks via SOQL/API (Phase 1), then E2E checks via Playwright Node.js scripts (Phase 2). Skips Phase 2 if Phase 1 has critical failures. Max 1 fix attempt per failing check.

## Inputs

You will receive:
- **Abstract test scenarios**: A file at `/tmp/test-scenarios.md` (S-NNN format with categories)
- **Org metadata**: A file at `/tmp/org-metadata.txt` (field names, types, picklist values per object)
- **Scratch org alias**: The target org alias (e.g., `pr-42`)
- **Frontdoor URL**: A pre-generated login URL for the scratch org
- **Instance URL**: The org's instance URL (e.g., `https://example.scratch.my.salesforce.com`)

## Execution Steps

### 1. Parse Inputs

Read `/tmp/test-scenarios.md` and extract:
- **Metadata**: Issue number, detected types, scenario count
- **Scenarios (S-NNN)**: Each with title, requirement, category, and what-to-verify description

Read `/tmp/org-metadata.txt` and extract:
- Object API names, field API names, field types, picklist values, required fields, relationship fields

If `/tmp/test-scenarios.md` is missing or empty, write an empty results file to `/tmp/qa-results.json` and stop:
```json
{
  "issue_number": null,
  "detected_types": [],
  "scenarios": [],
  "phase2_skipped": true,
  "phase2_skip_reason": "No test scenarios provided",
  "total": 0,
  "passed": 0,
  "failed": 0,
  "unresolved": 0
}
```

Read `~/.claude/skills/_qa-shared/type-registry.md` to resolve module paths for each detected type.

### 2. Materialize Scenarios

For each S-NNN scenario, use the org metadata and the scenario's category to produce a concrete check:

- **Data scenarios** (categories: positive, negative, boundary, bulk, data-integrity): Map the abstract "what to verify" to a specific SOQL query using real field API names from `/tmp/org-metadata.txt`. Determine which records to create, which DML to perform, and which SOQL assertion to run.
- **E2E scenarios** (category: e2e): Map to Playwright assertions with record page navigation. Identify which record IDs (created during Phase 1) to navigate to and what DOM assertions to make.

For each detected type, load:
- `~/.claude/skills/_qa-types/<type>/data.md` — data creation patterns (record setup, required fields, relationship wiring)
- `~/.claude/skills/_qa-types/<type>/run.md` — assertion patterns (Phase 1 SOQL checks AND Phase 2 Playwright templates)

### 3. Phase 1 — Data Checks

For each data-category scenario:

1. **Setup**: Create test data per `data.md` patterns. Batch where possible — create all records for related scenarios before running assertions.
2. **Check**: Run SOQL assertion per `run.md` Phase 1 patterns. Use assertion patterns from `~/.claude/skills/_qa-shared/sf-assertions.md`.
3. **Fix** (if the check failed with a code-level issue):
   - Identify the root cause (e.g., wrong field mapping in Apex, missing Flow condition, incorrect formula)
   - Modify the source code to fix the issue
   - Re-deploy: `sf project deploy start --source-dir force-app --target-org <alias> --wait 10`
   - Re-run the check ONCE
   - If the check still fails, record as `UNRESOLVED` and move on
   - **Max 1 fix attempt per check** (FR-012)
4. **Record**: Write PASS / FAIL / UNRESOLVED to `/tmp/qa-results.json` incrementally (overwrite the file after each scenario so it always contains valid JSON with all completed scenarios).

#### Efficiency: Batch Operations

- **Group record creation**: Create all test records for related scenarios before running assertions. For example, create all Opportunity records first (in sequential `sf data create record` commands or a single Apex script), then run all SOQL assertions.
- **Combine SOQL fields**: When multiple scenarios check different fields on the same record, query once with all needed fields in the SELECT clause rather than one query per field.
- **One setup, many assertions**: Write a single bash script that creates all Phase 1 test data, run it once, then run assertions against the created records.
- **Target pace**: ~2-3 turns per data test scenario (batch create + batch assert + record results).

### 4. Critical Failure Check

After all Phase 1 data checks complete: if more than 50% of data-category scenarios resulted in FAIL or UNRESOLVED, skip Phase 2:
- Set `phase2_skipped: true`
- Record: `"Phase 2 (E2E) skipped — too many data test failures indicate fundamental issues"`
- Proceed directly to final output

### 5. Phase 2 — E2E Checks

**Prerequisites**: Phase 1 did not hit the critical failure threshold. Frontdoor URL is available.

For each e2e-category scenario:

1. **Materialize**: Map to Playwright assertions using record IDs created during Phase 1 and the type-specific `run.md` Phase 2 template.
2. **Write script**: Copy the Playwright template from type `run.md`, fill in the SCENARIOS array with concrete record IDs, expected text, and assertion points.
3. **Run**: `mkdir -p /tmp/qa-screenshots` then execute the script with `node`.
4. **Fix** (if the check failed with a code-level issue): Same fix logic as data checks — identify root cause, modify source, re-deploy, re-run once. Max 1 fix attempt.
5. **Record**: Update `/tmp/qa-results.json` incrementally.

Write ONE `.mjs` script for ALL E2E scenarios and run it with `node`. The script must:

1. **Launch Chromium**: `import { chromium } from 'playwright';` with `executablePath: '/usr/bin/chromium'` and `args: ['--no-sandbox', '--disable-dev-shm-usage']`
2. **Authenticate once**: Navigate to the frontdoor URL. Wait for the page to load fully.
3. **Run all scenarios sequentially** in the same browser session:
   - Navigate directly to record pages: `${instanceUrl}/lightning/r/<Object>/<Id>/view`
   - Reuse record IDs created during Phase 1 data tests
   - Wrap each scenario in try/catch so failures don't abort remaining scenarios
   - On failure, capture a diagnostic screenshot before continuing
4. **Capture screenshots**: Save to `/tmp/qa-screenshots/<scenario-id>.png` at every assertion point and on every failure
5. **Close browser**: After all scenarios complete

**Wait strategies**: Use `page.waitForFunction()` checking for expected text or DOM elements. Do NOT use `waitForLoadState('networkidle')` — Lightning pages never fully reach network idle. Use `page.getByRole()` and `page.getByText()` for element selection — NOT CSS selectors.

Read `~/.claude/skills/_qa-types/<type>/run.md` for type-specific Playwright patterns (login, navigation, wait-for-load, assertions).

If the frontdoor URL is empty, skip Phase 2 and note "frontdoor URL not available" in results.

### 6. Output

Write results to `/tmp/qa-results.json` incrementally after each scenario completes (overwrite the file each time so it always contains valid JSON with all completed scenarios):

```json
{
  "issue_number": 42,
  "detected_types": ["flow"],
  "scenarios": [
    {
      "id": "S-001",
      "title": "...",
      "type": "flow",
      "phase": "data",
      "result": "PASS",
      "details": "...",
      "fix_attempted": false,
      "fix_details": null,
      "screenshot": null
    },
    {
      "id": "S-005",
      "title": "...",
      "type": "flow",
      "phase": "e2e",
      "result": "UNRESOLVED",
      "details": "Field value not visible on record page",
      "fix_attempted": true,
      "fix_details": "Modified FlowX to set field visibility — still fails after re-deploy",
      "screenshot": "/tmp/qa-screenshots/S-005.png"
    }
  ],
  "phase2_skipped": false,
  "phase2_skip_reason": null,
  "total": 10,
  "passed": 8,
  "failed": 1,
  "unresolved": 1
}
```

Result statuses:
- **PASS**: Check succeeded
- **FAIL**: Check failed, no code-level fix was possible (e.g., requirement ambiguity, config issue outside code)
- **UNRESOLVED**: Check failed, a fix was attempted but the check still fails after re-deploy

## Key Principles

- **Data first, E2E second**: Always run Phase 1 before Phase 2. Data checks are 100x faster and catch the same logic bugs.
- **Fail fast**: If data checks show fundamental problems (>50% failure), don't waste time on Playwright.
- **Single browser session**: Launch one Chromium instance, authenticate once, run all E2E scenarios sequentially. Direct record URLs instead of UI navigation.
- **Incremental results**: Write results after each scenario so partial results survive interruptions.
- **Fix and report**: For code-level failures, fix the source code, re-deploy, and re-run once. Do NOT post any report — a separate evaluation step handles that.
- **Max 1 fix attempt**: Each failing check gets at most one fix attempt. If it still fails, record as UNRESOLVED and move on (FR-012).
- **Evidence**: Capture screenshots at every assertion point and on every failure.
- **Graceful degradation**: If Playwright login fails, if SOQL errors out, if the org is unresponsive — log the failure, don't crash.
