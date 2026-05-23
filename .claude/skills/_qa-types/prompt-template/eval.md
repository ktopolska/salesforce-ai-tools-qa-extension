# Prompt Template — Evaluation Module

Output quality analysis and failure classification for Prompt Template tests. Used by qa-eval.

## Common Prompt Template Failure Categories

### 1. Unresolved Merge Fields

**Symptom**: Output contains literal `{!Record.FieldName}` placeholders instead of resolved values.

**Root causes**:
- Merge field references a field that doesn't exist on the input object
- Field API name is misspelled in the template
- The input record was not passed correctly to the template

**Fix suggestion**: "Verify merge field API names match the object's field definitions. Check that the input record ID is valid and the record has the referenced fields populated."

### 2. Empty or Minimal Output

**Symptom**: Template returns empty string, whitespace, or a very short response.

**Root causes**:
- Input record has empty fields that the template depends on
- Template instructions are too vague for the model to produce output
- Token limit set too low

**Fix suggestion**: "Ensure the input record has data in the fields the template references. Review the template instructions for clarity."

### 3. Irrelevant Output

**Symptom**: Template produces text but it doesn't reference the input record data.

**Root causes**:
- Merge fields are not effectively incorporated into the prompt instructions
- Template grounding is weak — model generates generic text
- Wrong template type for the use case (e.g., flex template when field-gen is needed)

**Fix suggestion**: "Strengthen the template instructions to explicitly reference merged field values. Consider adding few-shot examples."

### 4. Format Non-Compliance

**Symptom**: Template should produce a specific format (email, bullet points, JSON) but output is free-form.

**Root causes**:
- Template instructions don't clearly specify output format
- Model overrides format constraints at high temperature

**Fix suggestion**: "Add explicit format requirements to the template instructions (e.g., 'Respond with exactly 3 bullet points')."

### 5. Invocation Failure

**Symptom**: API call to invoke the template throws an exception.

**Root causes**:
- Template not deployed or not active
- Template developer name misspelled
- Missing permissions (EinsteinGPTPromptTemplateManager permission set)
- API version mismatch

**Fix suggestion**: "Verify the template is deployed with `sf project deploy start`. Check that the running user has the EinsteinGPTPromptTemplateManager permission set."

## Severity Classification

| Category | Default Severity | Rationale |
|----------|-----------------|-----------|
| Unresolved merge fields | High | Output is broken — shows template internals to users |
| Empty output | High | No value delivered — feature is non-functional |
| Irrelevant output | Medium | Feature works but quality is poor |
| Format non-compliance | Low | Output is usable but doesn't meet spec |
| Invocation failure | Critical | Template cannot be called at all |
