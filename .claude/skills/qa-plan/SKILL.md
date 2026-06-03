# QA Scenarios — Abstract Scenario Generation

Generate abstract, requirement-level test scenarios from a GitHub issue. This skill reads the issue body and triage plan comment, detects Salesforce metadata types, loads type-specific planning modules, and produces a structured set of scenarios describing WHAT to verify — without specifying HOW (no SOQL, no field API names, no record IDs).

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

For each detected type, read `~/.claude/skills/_qa-types/<type>/plan.md` to load scenario generation patterns specific to that type.

### 4. Generate Abstract Scenarios

For each requirement stated in the issue body:
1. Map it to one or more testable scenarios using the type-specific patterns
2. Assign a category: `positive`, `negative`, `boundary`, `bulk`, `data-integrity`, or `e2e`
3. Write the scenario with a plain-language description of the expected behavior
4. Trace back to the specific requirement from the issue

Guidelines:
- Every functional requirement in the issue must map to at least 1 scenario
- Include at least 1 negative case (verify what should NOT happen or should be rejected)
- Include at least 1 boundary condition (edge values, empty inputs, limits)
- Use the `e2e` category for scenarios that need UI verification (visual layout, navigation, user interaction)
- Aim for 5-15 scenarios per issue (adjust based on complexity)
- Keep scenarios abstract — describe expected behavior in plain language, not implementation details
- Do NOT include field API names, SOQL queries, record IDs, or org-specific metadata

### 5. Write the Scenarios File

Write the scenarios to `/tmp/test-scenarios.md` following this structure:

```markdown
# QA Scenarios: Issue #<number>

## Metadata
- Issue: #<number>
- Repository: <repo>
- Detected types: <comma-separated list>
- Generated: <ISO 8601 timestamp>
- Scenario count: <N>

## Scenarios

### S-001: <title>
- **Requirement**: "<traced requirement from issue>"
- **Category**: positive | negative | boundary | bulk | data-integrity | e2e
- **What to verify**: <plain-language description of the expected behavior>

### S-002: <title>
- **Requirement**: "<traced requirement from issue>"
- **Category**: positive | negative | boundary | bulk | data-integrity | e2e
- **What to verify**: <plain-language description of the expected behavior>
```

### 6. Post Summary Comment

Post a brief scenario summary on the issue so humans can see what will be tested:

```bash
cat > /tmp/qa-scenarios-summary.md <<'EOF'
**QA Scenarios**: <N> scenarios covering <detected types>

| ID | Category | What to verify |
|----|----------|----------------|
| S-001 | <category> | <one-line summary> |
| S-002 | <category> | <one-line summary> |
| ... | ... | ... |
EOF
gh issue comment $ISSUE_NUMBER --repo $REPO --body-file /tmp/qa-scenarios-summary.md
```

### 7. Output

The scenarios file at `/tmp/test-scenarios.md` will be consumed by the dev agent (as read-only context informing implementation) and by the dev-fix step (which materializes scenarios into concrete checks).

## Key Principles

- **Requirements-driven**: Scenarios come from what the issue ASKED for (business logic and expected behavior). They describe WHAT should be true, not HOW to check it.
- **Abstract**: No field API names, no SOQL queries, no record IDs, no org-specific metadata. The downstream dev-fix step handles materialization with real org metadata.
- **Type-aware**: Use type-specific patterns from `plan.md` modules for better scenario quality. Generic scenarios are a fallback, not the default.
- **Traceable**: Every scenario must link back to a specific requirement from the issue body.
- **Categorized**: Each scenario is tagged with a category so the dev-fix step knows how to materialize it (data check vs E2E vs boundary test).
