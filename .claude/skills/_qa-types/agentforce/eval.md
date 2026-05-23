# Agentforce — Evaluation Module

Conversation quality analysis and failure classification for Agentforce tests. Used by qa-eval.

## Common Agentforce Failure Categories

### 1. Topic Misrouting

**Symptom**: Agent routes the utterance to the wrong topic (e.g., user asks about a case but agent invokes the knowledge topic).

**Root causes**:
- Topic classification instructions are too broad or overlapping
- Utterance matches multiple topic scopes
- Missing negative examples in topic instructions

**Fix suggestion**: "Review topic scope definitions. Add disambiguation instructions or negative examples ('This topic does NOT handle...'). Consider narrowing the topic scope."

### 2. Action Failure

**Symptom**: Correct topic selected but the action fails to execute or returns an error.

**Root causes**:
- Action input mapping is wrong (model extracts wrong entity from utterance)
- Action's underlying Apex/Flow has a runtime error
- Required action input parameters not provided by the model
- Action permissions not configured

**Fix suggestion**: "Check the GenAiFunction's input schema and the model's parameter extraction. Verify the underlying Apex/Flow works independently via sf-testing."

### 3. Hallucination

**Symptom**: Agent responds with fabricated information not present in the org data.

**Root causes**:
- No grounding data available for the query
- Grounding retrieval returned no results but agent generated a response anyway
- Instructions don't enforce "say you don't know" behavior

**Fix suggestion**: "Add explicit grounding instructions: 'Only respond with information retrieved from org data. If no data is found, say you don't have that information.'"

### 4. Context Loss in Multi-Turn

**Symptom**: Agent forgets information from earlier turns (e.g., user says "update that case" but agent doesn't know which case).

**Root causes**:
- Session context not maintained between turns
- Too many turns exhausted context window
- Anaphora resolution failure (model can't resolve "that", "it", "the one")

**Fix suggestion**: "Verify session management is working. Consider adding explicit context-carrying instructions to the topic."

### 5. Escalation Failure

**Symptom**: Agent should have escalated to a human but didn't (or escalated when it shouldn't have).

**Root causes**:
- Escalation rules not configured or too narrow/broad
- Agent tries to handle out-of-scope requests instead of escalating
- Escalation action not wired to the topic

**Fix suggestion**: "Review escalation criteria in the topic configuration. Ensure out-of-scope detection works by testing with clearly off-topic utterances."

### 6. Channel-Specific Failure

**Symptom**: Agent works in one channel (web) but fails in another (Slack, API).

**Root causes**:
- Channel-specific formatting not handled (Slack markdown vs HTML)
- API response structure differs from UI expectations
- Authentication flow differs by channel

**Fix suggestion**: "Test across all configured channels. Check for channel-specific response formatting requirements."

## Severity Classification

| Category | Default Severity | Rationale |
|----------|-----------------|-----------|
| Topic misrouting | High | Fundamentally wrong behavior — user gets wrong response |
| Action failure | High | Feature broken — agent can't perform the requested task |
| Hallucination | Critical | Trust violation — agent provides false information |
| Context loss | Medium | Conversation quality degrades but individual turns work |
| Escalation failure | High | User stuck without help or unnecessarily transferred |
| Channel-specific | Medium | Works in primary channel, broken in secondary |
