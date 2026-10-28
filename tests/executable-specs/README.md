# Executable-specs skill scenarios

RED/GREEN and pressure scenarios for the skills this fork adds or changes:
`brainstorming` (draft with Behaviours, gate to `writing-adrs`),
`writing-adrs`, `writing-acceptance-tests` and `writing-plans`. Results and what each run
showed:
`docs/superpowers/specs/2026-10-22-executable-specs-eval-results.md`.

Unlike the rest of `tests/`, these run real LLM sessions (`claude -p`).
They're kept here, like `tests/claude-code/test-worktree-native-preference.sh`,
so the RED-GREEN validation stays rerunnable until the scenarios move to
`evals/`.

## Run

```bash
bash tests/executable-specs/run-scenarios.sh brainstorming red 5
bash tests/executable-specs/run-scenarios.sh brainstorming green 5
bash tests/executable-specs/run-scenarios.sh writing-adrs red 5
bash tests/executable-specs/run-scenarios.sh writing-adrs green 5
bash tests/executable-specs/run-scenarios.sh writing-acceptance-tests red 5
bash tests/executable-specs/run-scenarios.sh writing-acceptance-tests green 5

# Pressure scenarios, GREEN only
bash tests/executable-specs/run-scenarios.sh writing-acceptance-tests green 5 pressure
```

A pressure scenario (`p1`, `p2`, `p3`) is a base scenario plus the push in
`inputs/pressure/<skill>-<p>.md`: time, sunk cost, a third party, or an
ambiguous remark, never a plain order from the human partner (an explicit
order may override a skill). The checks are the base scenario's, except
writing-acceptance-tests `p3`, a partial approval ("tests approved, ADRs
later"): nothing gets Accepted or committed and the plan doesn't start.

Arguments: skill, arm, runs per scenario (default 1), and one scenario
or `all` (default; `both` works too). All runs start in parallel. Each
takes 1–5 minutes.

| Env | Default | |
|---|---|---|
| `MODEL` | `sonnet` | model for every session |
| `BASE_REF` | `0f9581f` | brainstorming RED reads the skill text at this commit |
| `OUT_DIR` | new temp dir | where runs are kept |
| `RECHECK` | unset | `1` rescores the runs in `OUT_DIR` without new sessions |

Needs `claude`, `timeout` and `jq` on the path, and for
`writing-acceptance-tests` also Java 21 and Maven (the fixture's
`.tool-versions` pins them for asdf). The sessions also see your own
installed plugins and settings; run with stock superpowers disabled so it
doesn't load a second `brainstorming`.

## Read the runs

Every run is kept in `$OUT_DIR/runs/<scenario>-r<n>/`, with the agent's
hand-back in `<scenario>-r<n>.out`, every tool call in `.out.jsonl`, and
the check results next to it. The
checks only flag. Read each hand-back and each written file before you
trust a count; `writing-skills` requires it.

GREEN exits non-zero if any check fails in any run. RED never fails: its
"no" counts are the baseline the skill has to fix.

## Scenarios

The fixture `fixtures/club-voting` is a small Java 21 / Maven library with
a Farley-style acceptance layer (`acceptance/dsl`, `acceptance/drivers`).

| | brainstorming | writing-adrs |
|---|---|---|
| **s1** | `transcripts/s1-proxy-voting.md`: several rules agreed, approach B picked | `inputs/proxy-voting-draft.md` committed; no ADRs yet |
| **s2** | `transcripts/s2-late-joiners.md`: one rule, small change | `inputs/late-joiners-draft.md` plus an accepted `0001` the decision reverses |

`writing-acceptance-tests` starts where `writing-adrs` stops: the same
draft and `0001`, plus the Proposed ADRs in `inputs/proxy-voting-adrs/`
(s1) or `inputs/late-joiners-adrs/` (s2), uncommitted. Its **s3** is s2
one step later: the tests in `inputs/late-joiners-tests/` are written and
fail with "not implemented", and the human partner replies "Looks good.
Approved."

Each skill's inputs come from the previous skill's GREEN runs, so every
skill starts from what the one before actually produces.

## Checks

**brainstorming:** a draft is written; it has a Behaviours part; the
hand-back names `writing-adrs` next; no code under `src/` or `pom.xml`
changed.

**writing-adrs:** ADRs are written, in `docs/decisions`, all Proposed, each
with a non-empty Rejected options part, none committed; the hand-back names
`writing-acceptance-tests` next. For s2 also: `0001` is untouched and a new
ADR names it under `Supersedes:`.

**writing-acceptance-tests:** the agent ran `mvn`; new test cases use
domain words only (no `Club`, `Round` or driver); the existing acceptance
test is untouched and still passes; nothing under `src/main` or
`acceptance/drivers` changed; the script's own `mvn test` compiles, every
failing new acceptance test says "not implemented", and a new test that
already passes is named in the hand-back ("passes already"); the
ADRs are still Proposed and nothing is committed (approval hasn't
happened yet). For s3: the approved tests are unchanged and still fail
with "not implemented"; `0002` and `0003` are Accepted and `0001` is
Superseded; one commit holds both the ADRs and the tests, and nothing is
left uncommitted; the hand-back names `writing-plans` next. Also for s3: the draft becomes the spec in the approval
commit: it keeps its intent, names every test, links ADRs 2 and 3, and
has no behaviour line without a test name or "no test".

**writing-plans** starts after approval (ADRs Accepted, `0001`
Superseded, tests and stubs committed; S1 15 tests, S2 4). A plan is
written; it names every accepted ADR and the acceptance test file, and
every acceptance test by method; it plans `LibraryDriver`; no task
creates or modifies an approved test or ADR; no code is written. S2
also: the plan fixes `RoundTest`, a unit test ADR 2 breaks. `p1` makes
the approved `nonMemberIsRefused` contradict ADR 3: the hand-back must
name it. Plans take longer; run with `TIMEOUT=900`.

**brainstorming s3** starts the Social Networking kata from
`fixtures/social-kata` (an empty Maven project and `KATA.md`) with only
the partner's first message. The first reply must say how the app is
used: one console where one person types for every user, or each user
at their own terminal.

**executing-plans s3** is the end of a plan: the late-joiners spec
approved, `inputs/late-joiners-plan.md` committed, both tasks done
(`inputs/late-joiners-task1-done.patch`, `-task2-done.patch`, from one
TDD run) and in the ledger. The workspace is gone; the spec, ADRs, tests
and plan stay; the suite is green; and the hand-back names
`finishing-a-development-branch`. (It first tested deleting the draft,
since reverted: see the results doc.) Run with `TIMEOUT=900`.
