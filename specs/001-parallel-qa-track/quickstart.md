# Quickstart: Parallel QA Track

## What this feature adds

Two new jobs to the `sf-ticket-to-pr.yml` workflow:

1. **qa-plan** — reads the issue requirements, generates a test plan (runs parallel with dev)
2. **qa-execute** — runs data + e2e tests against the scratch org, posts results on the PR

## Pipeline overview

```
triage ──┬──► execute (unchanged) ──┐
         │                          │
         └──► qa-plan ──────────────┴──► qa-execute ──► QA report on PR
```

## Files to create

| File | Where | Purpose |
|------|-------|---------|
| `qa-plan/SKILL.md` | `.claude/skills/` (shared repo) | Skill: generate test plan from issue |
| `qa-run/SKILL.md` | `.claude/skills/` (shared repo) | Skill: execute data + e2e tests |
| `qa-eval/SKILL.md` | `.claude/skills/` (shared repo) | Skill: evaluate results + post report |
| `_qa-types/flow/*.md` | `.claude/skills/` (shared repo) | Flow-specific testing modules |
| `_qa-types/prompt-template/*.md` | `.claude/skills/` (shared repo) | Prompt Template testing modules |
| `_qa-types/agentforce/*.md` | `.claude/skills/` (shared repo) | Agentforce testing modules |
| `_qa-shared/*.md` | `.claude/skills/` (shared repo) | Shared QA utilities |

## Files to modify

| File | Change |
|------|--------|
| `.github/workflows/sf-ticket-to-pr.yml` | Add `qa-plan` and `qa-execute` job definitions |
| `scripts/install-sf-ai-tools.sh` | No change needed — already symlinks all skills from shared repo |

## How to test locally

1. Create a test issue with clear requirements mentioning a Salesforce type
2. Manually run the qa-plan skill: `/qa-plan` with the issue number
3. Review the generated test plan for coverage and accuracy
4. Deploy code to a scratch org, then run `/qa-run` with the test plan
5. Review the QA report output

## How to test in CI

1. Push the workflow changes to a feature branch
2. Create a test issue with `@butler` mention
3. Observe the Actions run — verify qa-plan and execute run in parallel
4. Verify qa-execute starts only after both complete
5. Check the PR for the QA report comment, committed screenshots, and uploaded video artifacts
