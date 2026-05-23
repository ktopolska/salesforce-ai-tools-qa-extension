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

### Navigate to Template UI

If the template is surfaced in the UI (e.g., Einstein Copilot panel, action button):

```javascript
// Navigate to the record
await page.goto(`${instanceUrl}/lightning/r/<Object>/<recordId>/view`);

// Open the template invocation point (varies by integration)
// Example: Einstein copilot sidebar
await page.locator('button[title="Einstein"]').click();
await page.waitForSelector('.copilot-panel');
```

### Capture Output

```javascript
// Wait for generated text to appear
await page.waitForSelector('.generated-response', { timeout: 30000 });
const outputText = await page.locator('.generated-response').textContent();
```

### Screenshot Points

1. Before template invocation (record context visible)
2. After output is generated (template response visible)
3. Error state (if invocation fails)

```javascript
await page.screenshot({ path: '/tmp/qa-screenshots/<scenario-id>.png' });
```
