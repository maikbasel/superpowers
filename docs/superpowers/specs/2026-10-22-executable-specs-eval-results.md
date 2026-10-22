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
