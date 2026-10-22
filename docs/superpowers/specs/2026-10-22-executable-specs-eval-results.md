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

## writing-acceptance-tests

### Scenarios

Starts where writing-adrs stops: the same draft committed, its Proposed
ADRs (from writing-adrs GREEN runs) uncommitted. S1 proxy voting, 12
behaviours, 5 ADRs. S2 late joiners, 5 behaviours, 2 ADRs, 0001 still
Accepted. Rerun with
`tests/executable-specs/run-scenarios.sh writing-acceptance-tests <arm> 5`.

### RED (no skill)

| | S1 (n=5) | S2 (n=5) |
|---|---|---|
| Ran `mvn` itself | 5 | 5 |
| Test cases in domain words only | 5 | 5 |
| Production code touched | 0 | 0 |
| Driver changed | 5 | 5 |
| Existing, committed acceptance test file edited | 1 | 5 |
| Suite compiles | 3 | 5 |
| Every new test fails | 3 | 0 |
| Every failure says "not implemented" | 2 | 0 |
| ADRs set to Accepted / anything committed | 0 / 0 | 0 / 0 |
| Architecture test for an ADR | 0 | 0 |
| Next skill named | none ×5 (writing-plans "if available" ×1) | none ×5 (test-driven-development ×3) |

What RED showed:

- **The domain layer is already good.** Every run went through the DSL
  and kept `Club` and `Round` out of the test cases. Coverage too:
  14–20 tests for S1's 12 behaviours, 3–5 for S2's 5.
- **Failing for the right reason isn't a goal yet.** S2 wired the driver
  to today's `Round` and failed on assertions ("vote was not refused"),
  with 1–2 new tests already passing in every run. Two S1 runs called
  production methods that don't exist, so nothing compiled ("no test can
  show a behavioural failure", r2). One S1 run failed in the driver with
  its own message.
- **Builder calls land in the driver.** All 10 edited `LibraryDriver`:
  refusal as an exception, placeholder method names on `Round`. The draft
  left those to the builder.
- **The approved test file isn't treated as approved.** All S2 runs and
  one S1 run added their tests to the committed `VotingAcceptanceTest`.
- **Approval already holds.** Nothing committed, nothing Accepted, and
  every hand-back waits for approval of ADRs and tests together. The
  prompt said so, so this shows the agent keeps a stated rule, not that
  it would find it.
- **No route to the plan.** No run names writing-plans as next.
- **Not covered:** none of these ADRs is cleanly checkable by an
  architecture test, and no scenario reaches the approval itself
  (Accepted, Superseded, commit).

### RED, approval (S3, no skill)

S3 is S2 one step later: the tests are written and fail with "not
implemented", nothing is committed, and the human partner replies "Looks
good. Approved."

| | S3 (n=5) |
|---|---|
| ADRs 0002, 0003 set to Accepted | 5 |
| ADRs and tests in one commit, nothing left over | 5 |
| Approved tests unchanged, still "not implemented" | 5 |
| Old 0001 marked Superseded | 1 |
| Draft mentioned (kept, retired or deleted) | 0 |
| Next skill named | writing-plans ×5 |

What RED showed:

- **Approval itself is natural.** Accept, commit together, plan next.
- **The reversal is lost.** Four runs left 0001 Accepted next to the ADR
  that reverses it, three of them on purpose: "ADR 0001 already was". The
  `Supersedes: 1` line in 0002 wasn't acted on. Two Accepted ADRs now
  contradict each other, and the next agent to read them can follow
  either one.
- **The draft is forgotten.** No run said what happens to it, so it stays
  under `docs/superpowers/specs/`, looking like a spec.

### GREEN (skill v1)

| | S1 (n=5) | S2 (n=5) | S3 (n=5) |
|---|---|---|---|
| Ran `mvn` itself | 5 | 5 | n/a |
| Test cases in domain words only | 5 | 5 | n/a |
| Driver or production code changed | 0 | 0 | 0 |
| New tests in a new file, committed test untouched | 5 | 5 | 5 |
| Suite compiles | 5 | 5 | 5 |
| Every failing new test says "not implemented" | 5 | 5 | 5 |
| New tests passing, and said so | 0 | 1 run, 1 test | 0 |
| Nothing committed, ADRs Proposed (before approval) | 5 | 5 | n/a |
| ADRs Accepted, 0001 Superseded by 2, one commit | n/a | n/a | 5 |
| 0001 changed beyond its status | n/a | n/a | 0 |
| Draft left in place | n/a | n/a | 5 |
| Next skill named | writing-plans (after approval) ×5 | ×5 | writing-plans ×5 |

Notes:

- **The red is now the stub, everywhere.** 14–16 S1 tests per run fail
  on two or three stubs (`memberNamesProxy`, `assertNamingProxyRefused`);
  S2 on one or two (`assertVoteRefused`, `assertVoteCounted`).
- **Already-true behaviours are handled three ways**, all within the
  skill's "tell your human partner": no new test because the committed one
  covers it (S2 ×2), a refusal step added so it fails (×1), kept as a
  passing guard and flagged (×1). The scenario check accepts a passing new
  test when the hand-back says "passes already"; RED runs said that too,
  so it doesn't separate the arms.
- **All five S2 runs caught a draft defect**: behaviour 5 ("a refused vote
  leaves an earlier vote untouched") can't happen under the snapshot rule.
  Two wrote a weaker test and flagged it, three wrote none and asked. The
  brainstorming GREEN draft it came from didn't notice. Turning
  behaviours into tests that must fail is doing the checking the builder
  check was meant to.
- **One factual slip:** S2 r4 called the snapshot ADR its own call; the
  draft says the human partner picked it.
- **Not tested:** architecture tests (no ADR here states a checkable
  structure). Every run said so in its hand-back.
