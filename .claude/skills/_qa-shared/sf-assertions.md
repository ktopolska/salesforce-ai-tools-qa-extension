# SOQL Assertion Patterns

Reusable patterns for asserting record state, field values, counts, and relationships via SOQL queries and `sf data query`. Used by qa-run during Phase 1 (data testing).

## Query Execution

Run SOQL queries via the Salesforce CLI:

```bash
sf data query --query "<SOQL>" --target-org <alias> --json
```

Parse the JSON result to extract `.result.records` for assertions.

## Assertion Patterns

### Record Exists

Verify a record was created with expected field values:

```bash
sf data query --query "SELECT Id, <fields> FROM <Object> WHERE <criteria>" --target-org <alias> --json
```

**Assert**: `.result.totalSize` equals expected count. Field values match expectations.

### Field Value Changed

After triggering an automation (Flow, trigger), verify a field was updated:

```bash
# Before: capture initial state
sf data query --query "SELECT Id, <field> FROM <Object> WHERE Id = '<id>'" --target-org <alias> --json

# Trigger: update record to fire automation
sf data update record --sobject <Object> --record-id <id> --values "<TriggerField>=<NewValue>" --target-org <alias>

# After: verify field changed
sf data query --query "SELECT Id, <field> FROM <Object> WHERE Id = '<id>'" --target-org <alias> --json
```

**Assert**: Before value differs from after value. After value matches expected outcome.

### Record Count

Verify the correct number of records exist after a bulk operation:

```bash
sf data query --query "SELECT COUNT() FROM <Object> WHERE <criteria>" --target-org <alias> --json
```

**Assert**: `.result.totalSize` equals expected count.

### Related Records

Verify child records were created by an automation:

```bash
sf data query --query "SELECT Id, (SELECT Id, <fields> FROM <ChildRelationship>) FROM <ParentObject> WHERE Id = '<id>'" --target-org <alias> --json
```

**Assert**: Child relationship collection has expected count and field values.

### No Record Exists (Negative Test)

Verify an automation correctly prevented record creation or deleted a record:

```bash
sf data query --query "SELECT Id FROM <Object> WHERE <criteria>" --target-org <alias> --json
```

**Assert**: `.result.totalSize` equals 0.

## Result Formatting

For each assertion, capture:
- **Scenario ID**: DT-NNN from the test plan
- **Query**: The SOQL executed
- **Expected**: What the assertion expected
- **Actual**: What the query returned
- **Result**: PASS or FAIL
- **Details**: If FAIL, the specific mismatch (e.g., "Expected Status__c = 'Closed', got 'Open'")
