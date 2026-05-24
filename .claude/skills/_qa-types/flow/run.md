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

Write ONE `.mjs` script for ALL E2E scenarios. **Copy the template below** and fill in the `SCENARIOS` array with record IDs and assertions from Phase 1.

### Complete Script Template

Save as `/tmp/qa-e2e.mjs` and run with `node /tmp/qa-e2e.mjs`:

```js
import { chromium } from 'playwright';

const FRONTDOOR_URL = process.env.FRONTDOOR_URL || '<REPLACE_WITH_FRONTDOOR_URL>';
const INSTANCE_URL = process.env.INSTANCE_URL || '<REPLACE_WITH_INSTANCE_URL>';

// FILL IN: one entry per ET-NNN scenario from the test plan
const SCENARIOS = [
  {
    id: 'ET-001',
    objectName: 'Opportunity',    // Salesforce object API name
    recordId: '<ID_FROM_PHASE_1>', // record ID created in data tests
    assertions: [
      { type: 'text-visible', value: 'Closed Won' },
      { type: 'text-visible', value: 'Follow up: High-value deal' },
    ]
  },
  // Add more scenarios...
];

(async () => {
  const browser = await chromium.launch({
    executablePath: '/usr/bin/chromium',
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu']
  });
  const page = await browser.newPage();
  const results = [];

  // Authenticate once
  await page.goto(FRONTDOOR_URL);
  await page.waitForFunction(
    () => document.title !== '' && !document.title.includes('Login'),
    { timeout: 30000 }
  );

  for (const s of SCENARIOS) {
    try {
      // Navigate to record page
      await page.goto(`${INSTANCE_URL}/lightning/r/${s.objectName}/${s.recordId}/view`);
      await page.waitForFunction(
        () => document.querySelector('records-highlights-details') !== null
          || document.querySelector('records-record-layout-section') !== null,
        { timeout: 30000 }
      );

      // Run assertions
      const details = [];
      for (const a of s.assertions) {
        if (a.type === 'text-visible') {
          const visible = await page.getByText(a.value, { exact: false }).first().isVisible({ timeout: 10000 }).catch(() => false);
          details.push(`"${a.value}" visible: ${visible}`);
          if (!visible) throw new Error(`Expected text "${a.value}" not visible on page`);
        } else if (a.type === 'related-list-has-rows') {
          const heading = page.getByRole('heading', { name: a.listName });
          await heading.scrollIntoViewIfNeeded();
          const count = await heading.locator('..').locator('a[data-refid="recordId"]').count();
          details.push(`${a.listName} rows: ${count}`);
          if (count < (a.minRows || 1)) throw new Error(`Related list "${a.listName}" has ${count} rows, expected >= ${a.minRows || 1}`);
        } else if (a.type === 'error-banner') {
          const alert = page.getByRole('alert');
          const text = await alert.textContent({ timeout: 10000 });
          details.push(`Error banner: ${text}`);
          if (!text.includes(a.contains)) throw new Error(`Error banner missing "${a.contains}"`);
        }
      }

      await page.screenshot({ path: `/tmp/qa-screenshots/${s.id}.png` });
      results.push({ id: s.id, result: 'PASS', details: details.join('; ') });
    } catch (err) {
      await page.screenshot({ path: `/tmp/qa-screenshots/${s.id}-error.png` }).catch(() => {});
      results.push({ id: s.id, result: 'FAIL', details: err.message });
    }
  }

  await browser.close();
  console.log(JSON.stringify(results, null, 2));
})();
```

**How to use**: Copy this template, replace the `SCENARIOS` array entries with actual record IDs and assertions from Phase 1 results. Run with `node /tmp/qa-e2e.mjs`. Parse the JSON output to update `/tmp/qa-results.json`.
