# Flow — Run Module

SOQL assertion patterns and Playwright scenarios for Flow testing. Used by qa-run during Phase 1 (data assertions) and Phase 2 (e2e).

## Phase 1: SOQL Assertions

After triggering a Flow via DML (see data.md), assert outcomes using the patterns from `_qa-shared/sf-assertions.md`. Flow-specific patterns:

### Field Update Assertion

Verify the Flow updated a field on the triggering or related record:

```bash
sf data query --query "SELECT <FieldUpdatedByFlow> FROM <Object> WHERE Id = '<triggerId>'" --target-org <alias> --json
```

**Assert**: Field value matches what the Flow should have set.

### Child Record Creation

Verify the Flow created a related record (e.g., Task, Email, ContentNote):

```bash
sf data query --query "SELECT Id, Subject, Status FROM Task WHERE WhatId = '<triggerId>' AND Subject LIKE '%<expected pattern>%'" --target-org <alias> --json
```

**Assert**: `totalSize >= 1` and field values match.

### Flow Error Detection

If the Flow should add an error (validation-like behavior):

```bash
# Try to create/update a record that should be blocked
RESULT=$(sf data update record --sobject <Object> --record-id <id> --values "<TriggerField>=<BlockedValue>" --target-org <alias> --json 2>&1)
```

**Assert**: The command fails with an error message containing the expected Flow fault text.

## Phase 2: Playwright E2E

Write ONE `.mjs` script for ALL E2E scenarios. Use the patterns below.

### Playwright Patterns

#### Login via Frontdoor URL
```js
await page.goto(frontdoorUrl);
await page.waitForFunction(() => {
  return document.title !== '' && !document.title.includes('Login');
}, { timeout: 30000 });
```

#### Navigate to Record Page
```js
await page.goto(`${instanceUrl}/lightning/r/${objectName}/${recordId}/view`);
await page.waitForFunction(() => {
  return document.querySelector('records-highlights-details') !== null
    || document.querySelector('records-record-layout-section') !== null;
}, { timeout: 30000 });
```

#### Verify Field Value on Record Page
```js
const fieldVisible = await page.getByText(expectedValue).isVisible({ timeout: 10000 });
```

#### Verify Related List Has Records
```js
const relatedList = page.getByRole('heading', { name: relatedListLabel }).locator('..');
await relatedList.scrollIntoViewIfNeeded();
const rows = await relatedList.locator('a[data-refid="recordId"]').count();
```

#### Screenshot at Assertion Point
```js
await page.screenshot({ path: `/tmp/qa-screenshots/${scenarioId}.png`, fullPage: false });
```

#### Error Scenario — Verify Error Message
```js
const errorBanner = page.getByRole('alert');
const errorText = await errorBanner.textContent();
```

#### Try/Catch Wrapper Per Scenario
```js
try {
  // Navigate, assert, screenshot
} catch (err) {
  await page.screenshot({ path: `/tmp/qa-screenshots/${scenarioId}-error.png` });
  results.push({ id: scenarioId, result: 'FAIL', details: err.message });
}
```
