# Research: Parallel QA Track

## R1: GitHub Actions artifact passing between jobs

**Decision**: Use `actions/upload-artifact@v4` in qa-plan and `actions/download-artifact@v4` in qa-execute with a named artifact `test-plan`.

**Rationale**: Native GitHub Actions mechanism, no external storage needed. Artifacts are scoped to the workflow run, automatically cleaned up, and downloadable from the Actions UI for debugging.

**Alternatives considered**:
- Passing test plan via job output: rejected — job outputs have a 1MB limit, test plans with many scenarios could exceed this.
- Committing test plan to a branch: rejected — adds git noise and requires cleanup.

## R2: Playwright video recording in GitHub Actions

**Decision**: Use Playwright's built-in `video: 'on'` context option in the Node.js API. The qa-run skill instructs Claude to configure Playwright with `recordVideo: { dir: '/tmp/qa-videos/' }` and uploads the directory as a GitHub Actions artifact.

**Rationale**: Playwright natively supports video recording via the browser context. No additional tooling needed. Videos are saved as `.webm` files — typically 1-5MB per scenario, well within the 500MB artifact limit.

**Alternatives considered**:
- ffmpeg screen recording: rejected — adds a dependency and is harder to synchronize with test steps.
- Screenshot-only (no video): rejected — videos show timing and interaction flow that screenshots miss, especially for e2e debugging.

## R3: Text-based type detection accuracy

**Decision**: Use keyword matching with context awareness. Primary keywords: "Flow" (→ flow), "Prompt Template" / "PromptTemplate" (→ prompt-template), "Agentforce" / "Agent" (→ agentforce), "Apex" / "trigger" / "class" (→ apex). Context rules: "Agent" only maps to agentforce if co-occurring with "topic", "action", "utterance", or "Agentforce"; standalone "trigger" only maps to apex if not preceded by "record-triggered" (which maps to flow).

**Rationale**: Issue text written by developers is typically explicit about the metadata type they're changing. The triage plan comment adds further signal ("I'll create a record-triggered Flow..."). Ambiguity is rare and can be flagged in the test plan.

**Alternatives considered**:
- LLM-based classification: rejected for v1 — adds a Claude API call during qa-plan. Text matching is deterministic and free. Can add LLM fallback later if accuracy is insufficient.
- Org metadata query: rejected for qa-plan (no org access by design). Could be added as a verification step in qa-execute.

## R4: Scratch org cache reliability

**Decision**: Rely on the existing `actions/cache@v5` mechanism with key `scratch-auth-${{ env.SCRATCH_ORG_ALIAS }}`. qa-execute restores the same cache that execute created.

**Rationale**: The cache is already proven in the execute job. qa-execute runs after execute succeeds, so the cache is guaranteed to exist and be fresh. The `create-scratch-org.sh` script handles cache restoration transparently.

**Alternatives considered**:
- Passing org credentials via job outputs: rejected — security risk, credentials shouldn't flow through GitHub Actions outputs.
- Creating a second scratch org: rejected — doubles provisioning cost and time, introduces state divergence.

## R5: QA report format

**Decision**: Structured Markdown comment on the PR with sections: Summary (pass rate badge), Data Test Results (table), E2E Test Results (table with screenshot links), Failures (grouped by root cause with severity). Screenshots linked from `.verification/qa/` commit, videos linked from Actions artifacts.

**Rationale**: Matches the existing butler comment style (triage posts Markdown comments). Structured sections let reviewers scan quickly. Committing screenshots to git makes them render inline in the PR diff view.

**Alternatives considered**:
- GitHub Check Run with annotations: considered for future — provides better integration with PR checks UI but requires more complex API usage.
- Separate QA PR: rejected — fragments the review, humans need to cross-reference two PRs.

## R6: Failure handling — what happens when QA finds bugs

**Decision**: Report-only in v1. QA report is posted on the PR. If failures exist, the PR is labeled `qa-findings`. No auto-fix, no re-trigger of the dev agent.

**Rationale**: Auto-fix requires the QA agent to understand the codebase and the dev agent's implementation approach — that's the hard part of software engineering. Report-only provides 80% of the value (visibility) with 20% of the complexity.

**Future iterations**:
- v2: Re-trigger dev — post a structured comment with failures that triggers another `@butler` run.
- v3: Auto-fix — qa-execute pushes fixes directly, re-runs its own tests.
