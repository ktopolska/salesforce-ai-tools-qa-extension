# Agentforce — Test Planning Module

Generate test scenarios for Agentforce agent changes. Used by qa-plan when type detection identifies an Agentforce-related issue.

## Agent Components

| Component | Keywords | Testing Focus |
|-----------|----------|---------------|
| Topics | "topic", "topic classification" | Utterance routing, topic boundaries |
| Actions | "action", "GenAiFunction" | Action invocation, input/output mapping |
| Instructions | "instruction", "system prompt" | Behavior constraints, guardrails |
| Planner | "planner", "GenAiPlannerBundle" | Multi-step orchestration, action sequencing |

## Scenario Generation Patterns

### Data Test Scenarios (DT-NNN)

1. **Single-turn utterance routing**: Send a test utterance via Agent Runtime API → verify the correct topic is selected
2. **Action invocation**: Send an utterance that should trigger a specific action → verify the action executes and returns expected output
3. **Guardrail enforcement**: Send an utterance that should be blocked (out-of-scope, harmful) → verify the agent refuses or escalates
4. **Context grounding**: Send an utterance requiring record-specific context → verify the agent references the correct data
5. **Fallback behavior**: Send a gibberish utterance → verify the agent responds with a graceful "I don't understand" rather than hallucinating

### Multi-Turn Conversation Scenarios (DT-NNN)

6. **Multi-step workflow**: Send a sequence of utterances that form a complete workflow (e.g., "find my case" → "update the priority" → "confirm") → verify each step advances the conversation state correctly
7. **Context persistence**: Reference something from an earlier turn ("change that to high priority") → verify the agent resolves the reference
8. **Topic switching**: Start in one topic, switch to another mid-conversation → verify clean handoff

### E2E Test Scenarios (ET-NNN)

1. **Embedded agent UI**: Navigate to the page where the agent is surfaced → open the agent panel → send a message → verify response renders in the chat UI
2. **Action side effects**: Trigger an action via the agent UI → verify the resulting record changes are visible on the page

### API Invocation Pattern

Test via Agent Runtime API:

```bash
# Start a session
curl -X POST "https://<instance>/services/data/v65.0/einstein/agent-runtime/sessions" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"agentDefinition": "<BotApiName>"}'

# Send an utterance
curl -X POST "https://<instance>/services/data/v65.0/einstein/agent-runtime/sessions/<sessionId>/messages" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"message": {"text": "<utterance>", "sequenceNumber": 1}}'
```

## Scenario Template

```markdown
### DT-NNN: <descriptive title>
- **Type**: agentforce
- **Precondition**: <agent must be deployed and active, test data needed>
- **Action**: <utterance text or API call>
- **Expected**: <agent response content, topic selected, action invoked>
- **Requirement**: "<quote from issue requirements>"
```
