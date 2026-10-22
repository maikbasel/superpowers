# Executable-specs skill scenarios

RED/GREEN scenarios for the skills this fork adds or changes:
`brainstorming` (draft with Behaviours, gate to `writing-adrs`),
`writing-adrs` and `writing-acceptance-tests`. Results and what each run
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
```

Arguments: skill, arm, runs per scenario (default 1), and `s1`, `s2` or
`both` (default). All runs start in parallel. Each takes 1–3 minutes.

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
(s1) or `inputs/late-joiners-adrs/` (s2), uncommitted.

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
new acceptance test fails, and every failure says "not implemented"; the
ADRs are still Proposed and nothing is committed (approval hasn't
happened yet).
