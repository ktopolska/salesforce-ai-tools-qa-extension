# Prompt Template — Test Planning Module

Generate test scenarios for Salesforce Prompt Template changes. Used by qa-plan when type detection identifies a Prompt Template-related issue.

## Template Subtypes

| Subtype | Keywords | Testing Focus |
|---------|----------|---------------|
| Flex Template | "flex", "flexible" | Multi-purpose output, variable inputs |
| Field Generation | "field-generation", "field gen" | Single-field output, merge field resolution |
| Record Summary | "record-summary", "summary" | Record-scoped context, summarization quality |
| Sales Email | "sales email", "email" | Email formatting, personalization |

## Scenario Generation Patterns

### Data Test Scenarios (DT-NNN)

1. **Happy path invocation**: Invoke the template via API with valid input records/fields → verify the response contains expected content structure
2. **Input variation**: Invoke with different record types or field values → verify output adapts correctly
3. **Missing input**: Invoke with a required merge field missing → verify graceful handling (error message or fallback)
4. **Merge field resolution**: Verify all `{!Record.FieldName}` references resolve to actual field values, not literal placeholders
5. **Empty context**: Invoke with a record that has minimal data → verify the template doesn't hallucinate or produce nonsense

### E2E Test Scenarios (ET-NNN)

1. **UI invocation**: Navigate to the record where the template is surfaced (e.g., Einstein copilot panel, action button) → trigger the template → verify output renders correctly in the UI
2. **Output quality**: Capture the generated text → verify it matches the intent described in the issue requirements (e.g., "should summarize the opportunity's key details")

### API Invocation Pattern

Prompt Templates can be invoked via:

```bash
# Via Connect API
sf apex run --file /tmp/invoke-template.apex --target-org <alias>
```

Where the Apex file calls `ConnectApi.EinsteinLlm.generateMessages()` with the template developer name and input record ID.

Alternatively, via REST API if the template is exposed as a GenAiFunction.

## Scenario Template

```markdown
### DT-NNN: <descriptive title>
- **Type**: prompt-template
- **Precondition**: <records needed, template must be deployed>
- **Action**: <API invocation with specific input>
- **Expected**: <response structure, content quality criteria>
- **Requirement**: "<quote from issue requirements>"
```
