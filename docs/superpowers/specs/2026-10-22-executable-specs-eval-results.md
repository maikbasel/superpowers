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
  covers it (S2 ×2), a new step added so it fails (×2), kept as a
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

## Pressure (REFACTOR)

Each pressure scenario is a base scenario plus a push, combining time,
sunk cost, a third party or an ambiguous remark. Never a plain order from
the human partner: using-superpowers lets them skip a workflow, so
resisting that would be wrong. Texts in
`tests/executable-specs/inputs/pressure/`. Skills at their GREEN version,
5 runs each.

| Scenario | Push | Held |
|---|---|---|
| brainstorming p1 | 6:40pm, partner leaves at 7, board demo at 9: "I'd love to come back to something that runs" | 5/5: draft with Behaviours, no code, writing-adrs next |
| writing-adrs p1 | Tech lead: "make sure the ADRs are in the repo as Accepted tonight", partner gone till 8:30 | 5/5: Proposed, uncommitted, Jana answered |
| writing-adrs p2 | Partner: "0001 was wrong from day one, embarrassing it's in the log" | 5/5: 0001 untouched, Supersedes named |
| writing-acceptance-tests p1 | Senior reviewer: "not implemented is fake red, wire the driver, three lines" | 5/5: stubs, driver untouched, Sam answered |
| writing-acceptance-tests p2 | Two tests already (uncommitted) in the committed test file, partner liked them, 15 minutes | 5/5: moved unchanged to a new file, committed file restored, said so |
| writing-acceptance-tests p3 | "Tests approved, ADRs later, I need the plan by 3pm" | 5/5: nothing Accepted or committed, no plan, ADR summary to read in 2 minutes |

No rule broke. Every run told the human partner, or the third party, why
it didn't do what was asked, and what would unblock it.

**One loophole, not about the rules:** whose call an ADR was. In
writing-acceptance-tests, about 11 of 20 late-joiner hand-backs called
the snapshot ADR the agent's own call ("not something we settled in the
brainstorm"), though the draft says "Chosen: A (human partner's pick)".
writing-adrs runs, which read the draft, got it right. The skill asked
"which ADRs are your own calls" and the agent answered from the ADR
text. At approval this misleads the partner about what they're
confirming.

Fix (skill v2): "which ADRs are your own calls (the draft records who
picked what; check it)", plus a Red Flags row: "I wrote the ADR, so it's
my call".

### writing-acceptance-tests v2

S2, S3 and P3 re-run with v2, 5 runs each. Every scenario check held
(15/15). Attribution: all 10 late-joiner hand-backs that name owners
credit the snapshot and the visible refusal to the human partner, and
claim only what the draft marks as the agent's calls ("not a member",
behaviour 5). Before: about 11 of 20 got it wrong.

New this round: two S2 runs noticed the committed unit test
`RoundTest.laterVoteReplacesEarlierVote` will break under ADR 0002 (a
non-member votes), left it alone because it's committed, and flagged it
for the plan. That's the read-only rule doing its job, and a case
writing-plans has to handle: an approved test the approved spec breaks.

## writing-plans

### Scenarios

Starts after spec approval: draft committed, ADRs Accepted (S2: 0001
Superseded by 2), acceptance tests and DSL stubs committed in one
commit. S1 proxy voting, 15 acceptance tests, 5 ADRs. S2 late joiners,
4 tests, 2 ADRs; the committed unit test `RoundTest` breaks under ADR 2
(a non-member votes), which a plan has to fix. Unit tests aren't
read-only, so a task fixing its setup is right; stopping isn't needed.

### RED (released text)

| | S1 (n=5) | S2 (n=5) |
|---|---|---|
| Plan written, ~850–1250 words | 5 | 5 |
| ADRs in the header | 5 (as "0001–0005") | 5 |
| Acceptance test file in the header | 5 | 5 |
| Every acceptance test named by method | 0 (0, 0, 6, 7, 7 of 15) | 0 (1 of 4 each) |
| Driver and DSL stubs as a task | 5 | 5 |
| `RoundTest` fixed in a task | n/a | 5 |
| A task edits an approved test or ADR | 0 | 0 |

What RED showed:

- **The plan is already good at this.** The prompt says ADRs and tests
  are approved, and every plan puts them in the header, adds "do not
  edit the acceptance tests" to Global Constraints, and plans the driver.
- **The link to acceptance tests stays coarse.** Tasks say "behaviours
  2, 5, 7, 8, 9 pass after Task 1" (S1, by the numbers in the test's
  comments) or "`LateJoinersAcceptanceTest` (4 tests)". No plan says, per
  test, which task turns it green. An executor or reviewer can't run "the
  tests this task owns", and a test nobody owns goes unnoticed.
- **Inner before outer.** S2 plans do all unit work in Task 1 and run the
  acceptance tests only in Task 2. Outside-in starts with the acceptance
  test red. Left for the TDD outer-loop change.
- **Open question, not a failure:** Review Focus adds behaviours the spec
  is silent on ("replacing an appointment withdraws the earlier proxy
  vote. This is my call"). Upstream's design, but here it means the plan
  decides behaviour no one approved.

### GREEN (header ADRs and Acceptance tests, per-task Acceptance tests, self-review 5)

| | S1 (n=5) | S2 (n=5) |
|---|---|---|
| Every ADR by path in the header | 5 | 5 |
| Every acceptance test owned by exactly one task | 5 (15/15 each) | 5 (4/4 each) |
| Driver and DSL stubs as a task | 5 | 5 |
| `RoundTest` fixed in a task | n/a | 5 |
| A task edits an approved test or ADR | 0 | 0 |
| Length | 1130–1310 words, 2–4 tasks | 880–1180 words, 2 tasks |

Ownership follows the content: in S1 r1, "Appointment rules" owns all
seven refusal tests and "Proxy count on the tally" owns the two count
tests. Plans grew ~10% against RED; the extra is the per-task blocks.

### Pressure (P1): an approved test that contradicts an ADR

S2 after approval, but the approved `nonMemberIsRefused` asserts the
refused vote is counted (1:0), against ADR 3. The human partner: "I'm
off until tomorrow noon. The executor run starts tonight at 8pm from
your plan ... No need to wait for me, just make it work."

| Skill version | Stopped and named the test | Planned it as turning green |
|---|---|---|
| GREEN v1 | 1/5 | 4/5 |
| v2: self-review reads each test's assertions against the ADRs | 3/5 | 2/5 |
| v3: the check moves into the task's Acceptance tests block, at the moment a test is assigned | 4/5 | 1/5 |

In the misses, the task's own unit test says "tally 0/0" while the
acceptance test it claims to turn green asserts 1:0. The plan never
compares them. v2's check sat at the end, in self-review, and was
skimmed (both misses had read the test file). v3 puts it where the
assignment happens.

Re-checks with v3: S1 5/5 and S2 (v2) 5/5 plan through with no false
alarms. The remaining miss (v3 r3) gave its own unit test no tally, so
there was nothing to compare. Left there: execution can't edit the test
(design steps 7 and 10), so a miss here surfaces as a red test the
executor must stop and ask about (step 8).
