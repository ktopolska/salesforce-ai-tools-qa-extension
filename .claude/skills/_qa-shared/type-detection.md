# Type Detection Module

Infer Salesforce metadata types from issue text and triage plan comments. Used by the qa-plan skill to determine which `_qa-types/<type>/plan.md` modules to load.

## Supported Types

| Type Key | Module Path | Primary Keywords |
|----------|-------------|------------------|
| `flow` | `_qa-types/flow/` | Flow, record-triggered, screen flow, autolaunched flow, scheduled flow |
| `prompt-template` | `_qa-types/prompt-template/` | Prompt Template, PromptTemplate, GenAiPromptTemplate, flex template |
| `agentforce` | `_qa-types/agentforce/` | Agentforce, Agent, GenAiPlugin, GenAiFunction, topic, action, planner |

## Detection Rules

Parse the issue body and triage plan comment. For each supported type, check for keyword matches with these context-awareness rules:

### Flow
- **Match on**: "Flow", "record-triggered", "screen flow", "autolaunched", "scheduled flow", "before-save", "after-save", "flow trigger"
- **Context rule**: "record-triggered Flow" is unambiguous. Standalone "trigger" only maps to flow if preceded by "record-triggered" or "flow".

### Prompt Template
- **Match on**: "Prompt Template", "PromptTemplate", "GenAiPromptTemplate", "flex template", "field-generation", "record-summary"
- **Context rule**: No ambiguity expected — these terms are unique to Prompt Templates.

### Agentforce
- **Match on**: "Agentforce", "GenAiPlugin", "GenAiFunction", "GenAiPlannerBundle", "agent topic", "agent action"
- **Context rule**: Standalone "Agent" maps to agentforce ONLY if it co-occurs with "topic", "action", "utterance", "Agentforce", "planner", or "GenAi". Otherwise ignore — "Agent" is too generic.

### Apex (detection only — no type modules in v1)
- **Match on**: "Apex class", "Apex trigger", "Apex test", ".cls", ".trigger"
- **Context rule**: Standalone "trigger" maps to Apex only if NOT preceded by "record-triggered" or "flow". Standalone "class" is too generic — require "Apex class" or ".cls".
- **Action**: Log as detected type but note "no type-specific QA modules available — use generic scenarios".

## Output

Return a list of detected types with confidence:

```
Detected types:
- flow (high confidence — "record-triggered Flow" found in issue body)
- prompt-template (medium confidence — "template" found but context unclear)
```

## Ambiguity Handling

If no types are detected or confidence is low for all matches:
1. Default to generic testing scenarios (no type modules loaded)
2. Flag in the test plan: "Type detection inconclusive — using generic scenarios. Consider adding explicit type mentions to the issue."

If multiple types are detected, load all matching type modules — multi-type issues are common (e.g., "create a Flow and update the Prompt Template").
