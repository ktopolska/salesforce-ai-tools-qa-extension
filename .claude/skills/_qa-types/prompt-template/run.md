# Prompt Template — Run Module

Output quality assertions and Playwright scenarios for Prompt Template testing. Used by qa-run during Phase 1 (output assertions) and Phase 2 (e2e).

## Phase 1: Output Assertions

After invoking the template (see data.md), evaluate the output text.

### Content Quality Checks

For each invocation result, verify:

1. **Non-empty output**: The template returned text (not null, not empty, not just whitespace)
2. **Merge field resolution**: No unresolved `{!Record.FieldName}` placeholders appear in the output
3. **Relevance**: The output references data from the input record (e.g., contains the opportunity name, amount, or key details)
4. **Format compliance**: If the template specifies a format (email, summary, bullet points), verify the output follows it
5. **Length bounds**: Output is within reasonable length — not a single word, not 10,000 tokens

### Assertion Pattern

```bash
# Invoke template (see data.md for method)
OUTPUT=$(sf apex run --file /tmp/invoke-template.apex --target-org <alias> 2>&1 | grep 'TEMPLATE_OUTPUT:' | sed 's/.*TEMPLATE_OUTPUT://')

# Check non-empty
[ -n "$OUTPUT" ] && echo "PASS: Non-empty output" || echo "FAIL: Empty output"

# Check no unresolved merge fields
echo "$OUTPUT" | grep -q '{!' && echo "FAIL: Unresolved merge fields found" || echo "PASS: All merge fields resolved"

# Check relevance (contains expected data from input record)
echo "$OUTPUT" | grep -qi '<expected keyword from record>' && echo "PASS: Output references input data" || echo "FAIL: Output does not reference input data"
```

### Error Handling

If the template invocation fails (Apex exception, API error):
- Capture the error message
- Log as a FAIL with the error details
- Do not retry — report the failure for human review

## Phase 2: Playwright E2E

Write ONE `.mjs` script for ALL E2E scenarios. **Copy the template below** and fill in the `SCENARIOS` array.

### Complete Script Template

Save as `/tmp/qa-e2e.mjs` and run with `node /tmp/qa-e2e.mjs`:

```js
import { chromium } from 'playwright';

const FRONTDOOR_URL = process.env.FRONTDOOR_URL || '<REPLACE_WITH_FRONTDOOR_URL>';
const INSTANCE_URL = process.env.INSTANCE_URL || '<REPLACE_WITH_INSTANCE_URL>';

const SCENARIOS = [
  {
    id: 'ET-001',
    objectName: 'Opportunity',
    recordId: '<ID_FROM_PHASE_1>',
    action: 'open-einstein',  // 'navigate-only' | 'open-einstein'
    expectedOutput: 'summary of the opportunity',
  },
];

(async () => {
  const browser = await chromium.launch({
    executablePath: '/usr/bin/chromium',
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu']
  });
  const page = await browser.newPage();
  const results = [];

  await page.goto(FRONTDOOR_URL);
  await page.waitForFunction(
    () => document.title !== '' && !document.title.includes('Login'),
    { timeout: 30000 }
  );

  for (const s of SCENARIOS) {
    try {
      await page.goto(`${INSTANCE_URL}/lightning/r/${s.objectName}/${s.recordId}/view`);
      await page.waitForFunction(
        () => document.querySelector('records-highlights-details') !== null
          || document.querySelector('records-record-layout-section') !== null,
        { timeout: 30000 }
      );

      if (s.action === 'open-einstein') {
        const einsteinBtn = page.getByRole('button', { name: /einstein/i });
        await einsteinBtn.click();
        await page.waitForFunction(
          () => document.querySelector('[class*="copilot"]') !== null
            || document.querySelector('[class*="einstein"]') !== null,
          { timeout: 15000 }
        );
        await page.waitForFunction(
          () => {
            const responses = document.querySelectorAll('[class*="response"], [class*="message"]');
            return responses.length > 0;
          },
          { timeout: 30000 }
        );
        const outputText = await page.locator('[class*="response"]').last().textContent();
        const hasExpected = outputText.toLowerCase().includes(s.expectedOutput.toLowerCase());
        if (!hasExpected) throw new Error(`Output does not contain "${s.expectedOutput}": ${outputText.substring(0, 200)}`);
      }

      await page.screenshot({ path: `/tmp/qa-screenshots/${s.id}.png` });
      results.push({ id: s.id, result: 'PASS', details: 'assertions passed' });
    } catch (err) {
      await page.screenshot({ path: `/tmp/qa-screenshots/${s.id}-error.png` }).catch(() => {});
      results.push({ id: s.id, result: 'FAIL', details: err.message });
    }
  }

  await browser.close();
  console.log(JSON.stringify(results, null, 2));
})();
```

**How to use**: Copy template, fill `SCENARIOS` array, run with `node /tmp/qa-e2e.mjs`.
