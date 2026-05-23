# QA Run — Test Execution (Data + E2E)

Execute a test plan against a Salesforce scratch org. Runs two phases: fast data tests via SOQL/API (Phase 1), then e2e tests via Playwright (Phase 2). Skips Phase 2 if Phase 1 has critical failures.

## Inputs

You will receive:
- **Test plan**: A file at `/tmp/test-plan.md` (downloaded from GitHub Actions artifact)
- **Scratch org alias**: The target org alias (e.g., `pr-42`)
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

**Critical failure check**: After all data tests, if more than 50% of scenarios failed, flag Phase 2 as skipped:
- Record: "Phase 2 (E2E) skipped — too many data test failures indicate fundamental issues"
- Proceed directly to output

### 3. Phase 2 — E2E Tests (Playwright)

**Prerequisites**: Phase 1 did not hit the critical failure threshold.

#### Login to Scratch Org

```bash
FRONTDOOR_URL=$(sf org open --target-org <alias> --url-only --json | jq -r '.result.url')
```

If this fails, retry once:
```bash
FRONTDOOR_URL=$(sf org open --target-org <alias> --url-only --json | jq -r '.result.url')
```

If login still fails, skip Phase 2 with diagnostic: "Could not generate frontdoor URL — scratch org may be expired."

#### Configure Playwright

Use the Playwright MCP server (available via `~/.claude/mcp.json`). For each ET-NNN scenario:

1. Navigate to the frontdoor URL to authenticate
2. Navigate to the scenario's target page
3. Perform the interaction steps
4. At each screenshot point, capture: `playwright_screenshot`
5. Save screenshots to `/tmp/qa-screenshots/<scenario-id>.png`

#### Video Recording

Configure Playwright browser context with video recording:
- Videos save to `/tmp/qa-videos/`
- One video per scenario or one continuous video for all scenarios
- Format: `.webm`

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

Write results to `/tmp/qa-results.json` for consumption by qa-eval:

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
- **Evidence**: Capture screenshots at every assertion point. Record video of the full e2e journey.
- **No code changes**: This skill tests the deployed code. It does not modify source files.
- **Graceful degradation**: If Playwright login fails, if SOQL errors out, if the org is unresponsive — log the failure, don't crash.
