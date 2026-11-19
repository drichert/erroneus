# AI-directed development record — Erroneus

**Established:** 2026-11-19. **Status:** living project record; initial entry is retrospective context, not a claim that all earlier code was authored by AI.

## Roles

- **Human director:** defines the problem, quality bar, constraints, priorities, product/creative choices, acceptance criteria, and consequential approvals.
- **AI contributors:** propose engineering options; carry out authorized coding, tests and documentation; report failures and uncertainties. Specify agent/model names and code attribution only when evidenced.
- **Review:** an open PR is not an accepted feature. Automated tests are not substitutes for manual, audio, image or hardware verification.

## Director's brief

Design a playable experimental instrument emphasizing gesturally induced chaos, granular transformation, sample mangling and eventually beat-synchronized performance. Prioritize tempo cohesion and listening results over an elaborate control surface.

## Implementation context (source-backed summary)

The README documents four tracks, capture and sample capabilities, a slider panel, and continuing work on clock synchronization. Shared server-side musical clock is proposed in PR #8; it is not accepted merely because a PR exists.

## Decision log

### 2026-11-19 — Adopt AI-directed engineering and process evidence

**Decision:** Select tools for technical suitability rather than market popularity or the human director's personal coding familiarity. Represent this project as human-directed, AI-assisted engineering, separating director decisions from agent implementation. Record consequential tradeoffs, interventions, verification and unsuccessful attempts.

**Alternatives considered:** choosing technologies primarily to demonstrate hiring-market familiarity; implying human line-by-line authorship of agent contributions; maintaining only a code log without the direction and review decisions.

**Reason:** portfolio value should follow demonstrated product quality and responsible engineering direction. Do not retrofit unsupported claims about who wrote earlier code.

**Status:** process adopted for future work; prior PRs must be assessed individually before attributing authorship or claiming completed tests.

## Evidence, gaps and limits

Listening and timing behavior on the target laptop are not established by source inspection. Check actual audio behavior, CPU load and clock drift before presenting this as a finished musical instrument.

## Next director review

Evaluate PR #8 against real listening and clock tests. Capture test setup and director feedback.

## Update this record at meaningful milestones

For consequential engineering or product changes, add a short dated decision entry: **problem → options → chosen approach → human intervention → evidence → outcome / unresolved work**. Link PRs, tests, issues and screenshots where appropriate. Never invent verification or model identity. Keep private details out of public case studies; sanitized portfolio summaries are a separate publication decision.
