# Agentforce — Data Testing Module

Agent configuration verification and test data setup for Agentforce testing. Used by qa-run during Phase 1.

## Agent Configuration Verification

Before running conversation tests, verify the agent is properly configured:

```bash
# Check agent deployment status
sf data query --query "SELECT DeveloperName, Status FROM BotDefinition WHERE DeveloperName = '<AgentApiName>'" --target-org <alias> --json

# Check topics are assigned
sf data query --query "SELECT Id, DeveloperName FROM GenAiPlugin WHERE BotDefinition.DeveloperName = '<AgentApiName>'" --target-org <alias> --json

# Check actions are wired
sf data query --query "SELECT Id, DeveloperName FROM GenAiFunction WHERE GenAiPlugin.DeveloperName = '<PluginName>'" --target-org <alias> --json
```

## Test Data for Conversations

Create records that the agent's actions will need to query or operate on:

```bash
# Example: Create a Case for the agent to find
sf data create record --sobject Case --values "Subject='Broken Widget' Status='New' Priority='High' Description='Widget stopped working after update'" --target-org <alias> --json

# Example: Create an Account for context grounding
sf data create record --sobject Account --values "Name='Acme Corp' Industry='Technology'" --target-org <alias> --json
```

## Session Management

### Start a Session

```bash
ACCESS_TOKEN=$(sf org display --target-org <alias> --json | jq -r '.result.accessToken')
INSTANCE_URL=$(sf org display --target-org <alias> --json | jq -r '.result.instanceUrl')

SESSION=$(curl -s -X POST "$INSTANCE_URL/services/data/v65.0/einstein/agent-runtime/sessions" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"agentDefinition": "<BotApiName>", "isPreview": true}')

SESSION_ID=$(echo "$SESSION" | jq -r '.sessionId')
```

### Send an Utterance

```bash
RESPONSE=$(curl -s -X POST "$INSTANCE_URL/services/data/v65.0/einstein/agent-runtime/sessions/$SESSION_ID/messages" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"message\": {\"text\": \"<utterance>\", \"sequenceNumber\": <seq>}}")
```

### End a Session

```bash
curl -s -X DELETE "$INSTANCE_URL/services/data/v65.0/einstein/agent-runtime/sessions/$SESSION_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

## Multi-Turn Pattern

For multi-turn conversations, send utterances sequentially with incrementing sequence numbers. Capture the response after each turn for assertions.
