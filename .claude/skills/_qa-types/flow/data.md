# Flow — Data Testing Module

Test data creation and DML trigger patterns for Flow testing. Used by qa-run during Phase 1.

## Record Creation

Create test records using the Salesforce CLI:

```bash
sf data create record --sobject <Object> --values "<Field1>=<Value1> <Field2>=<Value2>" --target-org <alias> --json
```

Parse the JSON response to extract the record ID: `.result.id`

## Trigger Patterns

### Record-Triggered Flow (After Save)

1. **Create trigger record**: Create a record matching the Flow's entry criteria
2. **Wait briefly**: Allow async processing (platform events, etc.) — typically not needed for after-save flows
3. **Query results**: Verify the Flow's actions executed

```bash
# Create the trigger record
RESULT=$(sf data create record --sobject Opportunity --values "Name='Test Opp' StageName='Prospecting' CloseDate=2026-12-31 Amount=15000" --target-org <alias> --json)
RECORD_ID=$(echo "$RESULT" | jq -r '.result.id')

# Update to trigger the Flow
sf data update record --sobject Opportunity --record-id "$RECORD_ID" --values "StageName='Closed Won'" --target-org <alias>

# Assert: check the Flow's side effects
sf data query --query "SELECT Id, Status__c FROM Task WHERE WhatId = '$RECORD_ID'" --target-org <alias> --json
```

### Record-Triggered Flow (Before Save)

Before-save flows modify the triggering record itself. No separate query for side effects — just verify the record's fields after the trigger:

```bash
sf data create record --sobject Case --values "Subject='Test' Priority='Low'" --target-org <alias> --json
# Before-save flow may auto-set fields like Status or Category
sf data query --query "SELECT Status, Category__c FROM Case WHERE Subject = 'Test'" --target-org <alias> --json
```

### Bulk DML

Test bulkification by creating/updating multiple records:

```bash
# Create a CSV with 200 records
cat > /tmp/bulk-test.csv <<EOF
Name,StageName,CloseDate,Amount
Test Opp 1,Prospecting,2026-12-31,10000
Test Opp 2,Prospecting,2026-12-31,20000
...
EOF

sf data import bulk --sobject Opportunity --file /tmp/bulk-test.csv --target-org <alias> --wait 5
```

## Cleanup

After tests, delete test records to avoid polluting the org:

```bash
sf data delete record --sobject <Object> --record-id <id> --target-org <alias>
```

Or use bulk delete for multiple records.
