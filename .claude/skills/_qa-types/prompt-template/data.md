# Prompt Template — Data Testing Module

Test data creation and API setup for Prompt Template testing. Used by qa-run during Phase 1.

## Test Data Creation

Prompt Templates operate on records. Create test records with known field values so the template's output is predictable:

```bash
# Create a record with fields the template references via merge fields
sf data create record --sobject Opportunity --values "Name='Acme Deal' StageName='Negotiation' Amount=50000 Description='Enterprise license for 500 seats'" --target-org <alias> --json
```

Store the record ID for template invocation.

## Template Invocation

### Via Anonymous Apex

Create a temporary Apex file to invoke the template:

```bash
cat > /tmp/invoke-template.apex <<'APEX'
ConnectApi.EinsteinLlmGenerationInput input = new ConnectApi.EinsteinLlmGenerationInput();
input.promptTemplateDeveloperName = '<TemplateDeveloperName>';
input.inputParams = new Map<String, ConnectApi.WrappedValue>{
    'Input:Record' => ConnectApi.WrappedValue.toWrappedValue('<RecordId>')
};
ConnectApi.EinsteinLlmGenerationOutput output = ConnectApi.EinsteinLlm.generateMessages(input);
System.debug('TEMPLATE_OUTPUT:' + output.generationText);
APEX

sf apex run --file /tmp/invoke-template.apex --target-org <alias>
```

Parse the debug log output for lines containing `TEMPLATE_OUTPUT:` to extract the generated text.

### Via REST API

```bash
ACCESS_TOKEN=$(sf org display --target-org <alias> --json | jq -r '.result.accessToken')
INSTANCE_URL=$(sf org display --target-org <alias> --json | jq -r '.result.instanceUrl')

curl -s "$INSTANCE_URL/services/data/v65.0/einstein/prompt-templates/<TemplateDeveloperName>/generations" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"isPreview": false, "inputParams": {"Input:Record": {"value": "<RecordId>"}}}'
```

## Input Variations

Test the template with different input records to verify it adapts:

1. **Full data**: Record with all fields populated
2. **Minimal data**: Record with only required fields — template should handle gracefully
3. **Edge values**: Very long text fields, special characters, empty strings
