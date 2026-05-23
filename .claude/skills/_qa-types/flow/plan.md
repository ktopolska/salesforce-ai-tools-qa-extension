# Flow — Test Planning Module

Generate test scenarios for Salesforce Flow changes. Used by qa-plan when type detection identifies a Flow-related issue.

## Flow Subtypes

Identify which Flow subtype the issue describes:

| Subtype | Keywords | Testing Focus |
|---------|----------|---------------|
| Record-Triggered | "record-triggered", "before-save", "after-save" | DML triggers, field updates, order of execution |
| Screen Flow | "screen flow", "screen", "user input" | Navigation, input validation, branching |
| Autolaunched | "autolaunched", "invocable", "subflow" | API invocability, input/output variables |
| Scheduled | "scheduled", "batch", "time-based" | Schedule trigger, batch processing, time zones |
| Platform Event | "platform event", "event-triggered" | Event publishing, subscription, replay |

## Scenario Generation Patterns

### For Record-Triggered Flows

**Data test scenarios (DT-NNN)**:
1. **Happy path**: Create/update a record matching the trigger criteria → verify the Flow's actions executed (field updates, child records created, etc.)
2. **Boundary conditions**: Test field values at thresholds (e.g., Amount = exactly $10,000 if the Flow checks `Amount > 10000`)
3. **Negative case**: Create/update a record that does NOT match the trigger criteria → verify the Flow did NOT execute
4. **Bulk trigger**: Create/update 200 records in a single DML → verify the Flow handles bulk correctly (no "too many SOQL queries" errors)
5. **Before vs after save**: If before-save, verify field updates happen without extra DML. If after-save, verify related record changes.

**E2E test scenarios (ET-NNN)**:
1. **UI trigger**: Navigate to the object's record page, edit the trigger field via UI, save → verify the Flow's visible effects (field changes, related list updates)
2. **Error display**: Trigger a Flow that adds an error → verify the error message appears on the record page

### For Screen Flows

**Data test scenarios**: Typically none — screen flows are UI-driven.

**E2E test scenarios (ET-NNN)**:
1. **Full journey**: Launch the screen flow, complete all screens with valid input → verify the final outcome (record created/updated)
2. **Validation**: Enter invalid input on a screen → verify validation error appears
3. **Branching**: Navigate through a decision branch → verify the correct subsequent screen appears
4. **Back navigation**: Go back to a previous screen → verify state is preserved

### For Autolaunched Flows

**Data test scenarios (DT-NNN)**:
1. **Direct invocation**: Call the Flow via API or Apex → verify output variables and side effects
2. **Input variations**: Test with different input variable combinations, including nulls

**E2E test scenarios**: Typically none — autolaunched flows have no UI.

## Scenario Template

For each scenario, generate:

```markdown
### DT-NNN: <descriptive title>
- **Type**: flow
- **Precondition**: <records or state needed before the test>
- **Action**: <the DML operation or user action to perform>
- **Expected**: <the SOQL query to run and the expected result>
- **Requirement**: "<quote from issue requirements this traces to>"
```
