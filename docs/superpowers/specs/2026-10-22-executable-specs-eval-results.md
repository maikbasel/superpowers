# Executable specs — eval results

- **Spec:** 2026-10-22-executable-specs-design.md
- **Method:** writing-skills RED→GREEN. Fresh sonnet subagents, one fixture
  copy each, 5 per arm. Each starts from a transcript snapshot just before
  the write-up and continues the session for real. Every reply and every
  resulting repo read by hand.
- **Fixture:** `club-voting`, a small Java/JUnit library with a Farley-style
  acceptance layer already in place (`acceptance/dsl/VotingDsl`,
  `acceptance/drivers/LibraryDriver`, one acceptance test, one unit test).

## brainstorming

### Scenarios

**S1 — proxy voting (meant as a project).** Several rules agreed in
conversation (single round, one proxy per holder, own vote wins, named
before close, proxy count in result). Two approaches laid out; the human
partner picks B: "B. Go ahead."

**S2 — late joiners (small change).** One rule (eligibility fixed at round
open, refusal with a reason). Two approaches; the human partner picks A:
"A. This is a small one, go ahead."

### RED (released text, 2026-10-22)

| | S1 (n=5) | S2 (n=5) |
|---|---|---|
| Prose design doc committed as the lasting spec | 5 | 5 |
| Acceptance test files written | 0 | 0 |
| ADR written | 0 | 0 |
| Rejected approach recorded (in the design doc) | 5 | 5 |
| Next skill named | writing-plans ×5 | writing-plans ×5 |
| Builder check run | 2 | n/a (small) |
| Sized as a project | 1 (one more "small-to-medium") | 0 |

What the baseline showed:

- **Behaviour stays in prose.** Every run committed a design doc and
  handed off to writing-plans. No run wrote a test.
- **Tests are left to the builder.** All 10 docs mention acceptance tests
  only as a layout instruction ("Acceptance tests go through the DSL and
  driver", "test layout: new acceptance scenarios in the DSL"). What the
  tests assert is never pinned.
- **Agent-made rules hide in "My calls".** S1 runs invented 4–8 behaviour
  rules each (no chains, no self-appointment, proxy votes after close
  refused, appointments can't be withdrawn). They differ between runs and
  exist only as prose bullets for the human to catch while reading. These
  are exactly the behaviours an acceptance test should pin and the human
  should approve as tests.
- **Rejected options survive, but in the wrong place.** All runs kept the
  dropped approach, but only in the design doc, which is meant to become a
  draft. The ADR is where it should land.
- **The existing DSL is respected.** All runs said new tests should use
  `VotingDsl` and `LibraryDriver`. Vocabulary reuse is a likely strength to
  keep, not a gap.
- **Sizing drift (not in scope).** 4 of 5 S1 runs sized the change as
  small, so the builder check ran only twice. We keep sizing unchanged, but
  this means the "small changes get acceptance tests too" rule carries most
  of the load.

### GREEN (draft + Behaviours + gate to writing-adrs)

Same scenarios, prompt and fixture; only the skill text differs.

| | S1 (n=5) | S2 (n=5) |
|---|---|---|
| Draft has a Behaviours part | 5 | 5 |
| Behaviour lines (range) | 11–12 | 4–5 |
| Agent's own calls listed as behaviours | 5 | 5 |
| Asks the human partner to approve the draft | 0 | 0 |
| Product or test code written | 0 | 0 |
| Next skill named | writing-adrs ×5 | writing-adrs ×5 |
| Builder check run | 0 | n/a (small) |

What changed:

- **Every rule is now a checkable line.** The 4–8 agent-made rules that
  RED hid in "My calls" now sit in Behaviours as concrete examples, marked
  as the agent's call (e.g. "Naming yourself as your proxy is refused.").
- **The handoff tells the human what they'll approve.** Every message says
  the ADRs and acceptance tests come next and are what gets approved.
- **One run (S1 r1) raised a real question** (proxy chains) instead of
  silently deciding it, and held the handoff until it's answered.
- **Not fixed, out of scope:** S1 was sized as small in all 5 runs, so the
  builder check never ran. Sizing is unchanged on purpose; the Behaviours
  part now carries the rules either way.

## writing-adrs

### Scenarios

Both start from a GREEN brainstorming draft, committed. The prompt says the
workflow's next step is to record the draft's decisions as ADRs.

**S1 — proxy voting, no ADRs yet.** Draft from brainstorming GREEN S1 r3:
12 behaviours, 7 of them the agent's own calls. The repo has no ADR
convention.

**S2 — late joiners, conflicting ADR.** Draft from brainstorming GREEN
S2 r3, plus an accepted `docs/decisions/0001-membership-checked-by-website.md`
("`Round` accepts a vote from anyone") that the new snapshot decision
reverses.

### RED (no skill)

| | S1 (n=5, 13 ADRs) | S2 (n=5, 10 new ADRs) |
|---|---|---|
| One ADR per real decision, behaviours left out | 5 | 5 |
| Location | `docs/adr` (invented) ×5 | `docs/decisions` (copied) ×5 |
| New ADRs written as Accepted | 13/13 | 10/10 |
| Rejected options part | 3/13 | 10/10 (copied from 0001) |
| Committed before approval | 5 | 5 |
| Old ADR marked superseded without asking | n/a | 4 |
| Agent's own decisions recorded | 0 | 0 |
| Next step | acceptance tests, vaguely ×4 | the plan ×3, none ×2 |

What RED showed:

- **Granularity is already good.** No run turned behaviours into ADRs.
- **Approval is skipped three ways:** Accepted written directly, committed
  straight away, and the old ADR rewritten on the agent's own say-so.
- **Rejected options appear only when a template demands them.**
- **Own calls get dropped, verbatim:** "recording them would present them
  as decided." Some are real decisions (no proxy chains), so they'd be lost.
- **No route to the tests.** S2 runs went for the plan.

### GREEN (skill v1)

| | S1 (n=5, 24 ADRs) | S2 (n=5, 10 new ADRs) |
|---|---|---|
| Status Proposed | 24/24 | 10/10 |
| Rejected options, non-empty | 24/24 | 10/10 |
| Location `docs/decisions` | 5 | 5 |
| Committed | 0 | 0 |
| Existing ADR modified | n/a | 0 |
| `Supersedes:` names the reversed ADR | n/a | 5 |
| Agent's own decisions as Proposed ADRs, marked as theirs | 5 (1–2 each) | 1 |
| Next skill named | writing-acceptance-tests ×5 | writing-acceptance-tests ×5 |

Notes:

- **More ADRs in S1** (4–6 vs 2–3), because own calls that are real
  decisions now get one (no chains ×5, a new appointment replaces the old
  ×3). The rest of the behaviours still go to tests.
- **Projects with a format keep it.** Three S2 runs used 0001's
  `## Status` heading instead of the template's `Status:` line, with every
  required part present. That's the intended reading of "whatever format
  the project uses".
- **Borderline:** one S1 run gave "own vote beats proxy vote" its own ADR,
  but used it to flag a contradiction in the draft ("whichever is cast
  first"). Worth watching for over-recording in the real run.
