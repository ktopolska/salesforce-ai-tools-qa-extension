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

### Navigate to Record

```javascript
// Go to the record page where the Flow's effects should be visible
await page.goto(`${instanceUrl}/lightning/r/<Object>/<recordId>/view`);
await page.waitForSelector('records-record-layout-section');
```

### Verify Field on Record Page

```javascript
// Check that a field updated by the Flow shows the expected value
const fieldValue = await page.locator('lightning-formatted-text').filter({ hasText: '<expected>' }).textContent();
```

### Verify Related List

```javascript
// Check that a child record created by the Flow appears in the related list
await page.locator('lst-related-list-single-container').filter({ hasText: '<RelatedListLabel>' }).click();
await page.waitForSelector('lightning-datatable');
const rows = await page.locator('lightning-datatable tbody tr').count();
```

### Screenshot Points

Capture screenshots at:
1. Record page after triggering the Flow (shows field updates)
2. Related list showing created child records
3. Error message display (for negative tests)

```javascript
await page.screenshot({ path: '/tmp/qa-screenshots/<scenario-id>.png', fullPage: false });
```
