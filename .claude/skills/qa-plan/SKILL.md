# QA Plan — Test Plan Generation from Requirements

Generate a requirements-driven test plan from a GitHub issue. This skill reads the issue body and triage plan comment, detects Salesforce metadata types, queries the scratch org for field-level metadata, loads type-specific planning modules, and produces a structured test plan.

## Inputs

You will receive:
- `ISSUE_NUMBER`: The GitHub issue number
- `REPO`: The GitHub repository (owner/repo format)
- `SCRATCH_ORG_ALIAS`: The scratch org alias for metadata queries

## Execution Steps

### 1. Read the Issue

```bash
gh issue view $ISSUE_NUMBER --repo $REPO --comments
```

Extract:
- **Issue body**: The requirements (first block of text)
- **Triage comment**: The most recent bot comment containing the dev plan

### 2. Detect Types

Read `~/.claude/skills/_qa-shared/type-detection.md` for detection rules.

Parse the issue body and triage comment against the keyword rules. Output the detected types with confidence levels.

### 3. Query Org Metadata

For each object referenced in the issue or triage plan, query the scratch org for field-level metadata:

```bash
sf sobject describe <ObjectName> --target-org $SCRATCH_ORG_ALIAS --json
```

Extract:
- Field API names and labels
- Field types (text, number, picklist, lookup, etc.)
- Picklist values (for picklist fields)
- Required fields
- Object relationships (lookups, master-detail)

Use this metadata to ensure test scenarios reference real field API names instead of guessed names.

**Fallback**: If the org query fails (expired org, network error, object not found), continue generating scenarios from the issue text alone. Add a note to the test plan: "Field names are unverified — org metadata query failed."

### 4. Load Type Planning Modules

Read `~/.claude/skills/_qa-shared/type-registry.md` to resolve module paths.

For each detected type, read `~/.claude/skills/_qa-types/<type>/plan.md` to load scenario generation patterns.

### 5. Generate Test Scenarios

For each requirement stated in the issue body:
1. Map it to a testable scenario using the type-specific patterns
2. Determine if it's a data test (DT-NNN) or e2e test (ET-NNN)
3. Write the scenario with all required fields (precondition, action, expected, requirement trace)
4. Use queried field API names from Step 3 for precision

Guidelines:
- The issue description defines WHAT to test (business logic, expected behavior)
- The org metadata provides exact field names, types, and relationships
- Every functional requirement in the issue should map to at least one scenario
- Include boundary condition scenarios for any numeric thresholds or conditional logic
- Include at least one negative test (verify what should NOT happen)
- Aim for 5-15 total scenarios per issue (adjust based on complexity)

### 6. Assemble the Test Plan

Write the test plan to `/tmp/test-plan.md` following this structure:

```markdown
# Test Plan: Issue #<number>

## Metadata
- Issue: #<number>
- Repository: <repo>
- Detected types: <comma-separated list>
- Generated: <ISO 8601 timestamp>
- Scenario count: <N>
- Org metadata: <queried | unavailable>

## Data Test Scenarios

### DT-001: <title>
- **Type**: <type>
- **Precondition**: <setup>
- **Action**: <operation>
- **Expected**: <assertion>
- **Requirement**: "<traced requirement>"

[... more DT scenarios ...]

## E2E Test Scenarios

### ET-001: <title>
- **Type**: <type>
- **Navigation**: <page/component>
- **Steps**: <interaction sequence>
- **Expected**: <visual/functional assertion>
- **Screenshot points**: <which steps to capture>
- **Requirement**: "<traced requirement>"

[... more ET scenarios ...]
```

### 7. Post Summary Comment

Post a summary on the issue so humans can see what will be tested:

```bash
cat > /tmp/qa-plan-summary.md <<'EOF'
**QA Plan**: <N> test scenarios covering <types>

| Phase | Count | Focus |
|-------|-------|-------|
| Data tests | <n> | <brief description> |
| E2E tests | <n> | <brief description> |

<any ambiguities or caveats>
EOF
gh issue comment $ISSUE_NUMBER --repo $REPO --body-file /tmp/qa-plan-summary.md
```

### 8. Output

The test plan file at `/tmp/test-plan.md` will be consumed by the qa-run step that follows in the same job.

## Key Principles

- **Requirements-driven with org-informed precision**: Scenarios come from what the issue ASKED for (business logic). The org metadata provides exact field names and types so scenarios are precise, not generic.
- **Type-aware**: Use type-specific patterns for better scenario quality. Generic scenarios are a fallback, not the default.
- **Traceable**: Every scenario must link back to a specific requirement from the issue body.
- **Graceful fallback**: If org metadata is unavailable, generate scenarios from issue text alone and flag unverified field names.
