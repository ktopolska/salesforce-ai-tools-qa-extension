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

#### Open Einstein Copilot Panel
```js
const einsteinBtn = page.getByRole('button', { name: /einstein/i });
await einsteinBtn.click();
await page.waitForFunction(() => {
  return document.querySelector('[class*="copilot"]') !== null
    || document.querySelector('[class*="einstein"]') !== null;
}, { timeout: 15000 });
```

#### Capture Generated Output
```js
await page.waitForFunction(() => {
  const responses = document.querySelectorAll('[class*="response"], [class*="message"]');
  return responses.length > 0;
}, { timeout: 30000 });
const outputText = await page.locator('[class*="response"]').last().textContent();
```

#### Screenshot at Assertion Point
```js
await page.screenshot({ path: `/tmp/qa-screenshots/${scenarioId}.png` });
```

#### Try/Catch Wrapper Per Scenario
```js
try {
  // Navigate, open panel, capture output, screenshot
} catch (err) {
  await page.screenshot({ path: `/tmp/qa-screenshots/${scenarioId}-error.png` });
  results.push({ id: scenarioId, result: 'FAIL', details: err.message });
}
```
