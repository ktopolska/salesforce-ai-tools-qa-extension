# Flow — Evaluation Module

Root cause analysis patterns for Flow test failures. Used by qa-eval to classify failures and suggest fixes.

## Common Flow Failure Categories

### 1. Missing Entry Criteria

**Symptom**: The Flow did not fire — no side effects observed after DML trigger.

**Root causes**:
- Entry condition references a field that wasn't set on the test record
- Entry condition uses `IS CHANGED` but the field was set on insert, not update
- Record type filter excludes the test record
- Flow is inactive or was not deployed

**Fix suggestion**: "Verify the Flow's entry conditions match the test record's field values. Check if the Flow requires an update (not insert) to trigger."

### 2. Wrong Field Update

**Symptom**: The Flow fired but set a field to an unexpected value.

**Root causes**:
- Decision element has wrong operator (e.g., `>=` vs `>`)
- Formula or assignment uses wrong field reference
- Multiple Flows updating the same field — order-of-execution conflict
- Before-save vs after-save confusion — before-save can't update related records

**Fix suggestion**: "Check the decision element operators and assignment values in the Flow. If multiple Flows touch this field, review execution order."

### 3. Missing Child Records

**Symptom**: The Flow should have created related records (Tasks, Emails, etc.) but none exist.

**Root causes**:
- Create Records element references wrong parent field
- Required fields on child object not set in the Flow
- Flow reached a fault path instead of the create path

**Fix suggestion**: "Check the Create Records element for correct parent lookup field assignment and verify all required fields on the child object are set."

### 4. Bulk Processing Failure

**Symptom**: Works for 1 record but fails for 200 records.

**Root causes**:
- SOQL query inside a loop (governor limit hit)
- Get Records without proper filtering (returns too many records)
- Non-bulkified Apex invocable action called by the Flow

**Fix suggestion**: "Check for SOQL or DML operations inside loops. Verify Get Records elements have efficient filters."

### 5. Order of Execution Issue

**Symptom**: Flow fires but sees stale field values, or fires multiple times unexpectedly.

**Root causes**:
- Before-save flow reads a field that hasn't been committed yet
- After-save flow triggers a recursive update
- Workflow rules or Process Builder running alongside the Flow

**Fix suggestion**: "Review the Salesforce order of execution. Check for recursive triggers and consider adding recursion guards."

## Severity Classification

| Category | Default Severity | Rationale |
|----------|-----------------|-----------|
| Missing entry criteria | High | Flow is not executing at all — core functionality broken |
| Wrong field update | High | Logic error — produces incorrect data |
| Missing child records | Medium | Side effect missing but main record may be correct |
| Bulk processing failure | Critical | Will fail in production with real data volumes |
| Order of execution | Medium | Subtle timing issue — may not manifest in all scenarios |
