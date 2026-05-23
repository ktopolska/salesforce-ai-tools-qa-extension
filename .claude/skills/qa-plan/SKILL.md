# QA Plan — Test Plan Generation from Requirements

Generate a requirements-driven test plan from a GitHub issue. This skill reads the issue body and triage plan comment, detects Salesforce metadata types, loads type-specific planning modules, and produces a structured test plan as output.

**No scratch org required.** This is pure text analysis.

## Inputs

You will receive:
- `ISSUE_NUMBER`: The GitHub issue number
- `REPO`: The GitHub repository (owner/repo format)

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

### 3. Load Type Planning Modules

Read `~/.claude/skills/_qa-shared/type-registry.md` to resolve module paths.

For each detected type, read `~/.claude/skills/_qa-types/<type>/plan.md` to load scenario generation patterns.

### 4. Generate Test Scenarios

For each requirement stated in the issue body:
1. Map it to a testable scenario using the type-specific patterns
2. Determine if it's a data test (DT-NNN) or e2e test (ET-NNN)
3. Write the scenario with all required fields (precondition, action, expected, requirement trace)

Guidelines:
- Every functional requirement in the issue should map to at least one scenario
- Include boundary condition scenarios for any numeric thresholds or conditional logic
- Include at least one negative test (verify what should NOT happen)
- Aim for 5-15 total scenarios per issue (adjust based on complexity)

### 5. Assemble the Test Plan

Write the test plan to `/tmp/test-plan.md` following this structure:

```markdown
# Test Plan: Issue #<number>

## Metadata
- Issue: #<number>
- Repository: <repo>
- Detected types: <comma-separated list>
- Generated: <ISO 8601 timestamp>
- Scenario count: <N>

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

### 6. Post Summary Comment

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

### 7. Output

The test plan file at `/tmp/test-plan.md` will be uploaded as a GitHub Actions artifact by the workflow step that follows this skill invocation.

## Key Principles

- **Requirements-driven**: Scenarios come from what the issue ASKED for, not what was built. This catches requirements-implementation gaps.
- **Type-aware**: Use type-specific patterns for better scenario quality. Generic scenarios are a fallback, not the default.
- **Traceable**: Every scenario must link back to a specific requirement from the issue body.
- **No org access**: This skill runs without a scratch org. All analysis is text-based.
