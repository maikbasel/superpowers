# Executable specs: intent

## Why this exists

Superpowers writes specs as prose, and an LLM reviewer checks code against
them. That check is a judgement call. Prose specs drift and can't fail.

We want the part of the spec a machine can check to be checked. If a
behaviour isn't met, a test fails. Code generation stays
nondeterministic; verification doesn't have to be.

## The idea

- Behaviour lives in acceptance tests, written before any code (ATDD,
  outside-in, as Dave Farley teaches it).
- The design doc stays, as upstream: intent, goals, constraints,
  approaches and decisions in prose. Its behaviour lines point to the
  acceptance tests instead of restating them. Not everything can be a
  test.
- The tests bind what the software does; the design doc says why. It is
  a snapshot of the thinking at the time, as design docs at Google are
  (Ubl): the reasoning may age, the behaviour can't, because the tests
  carry it.
- The agent may not change approved tests to make its work pass. Only
  the human partner can approve a change.

## What we keep

Everything upstream does: the questions, playback, spikes, visual
companion, sizing, design doc, small tasks, subagents and reviews. We
change as little as possible.

## Principles

- Tests describe the domain, not the UI or code.
- Spikes teach us things. Their code is thrown away.
- If a test looks wrong, stop and ask. Don't work around it.
- Keep it brief, in the same style as superpowers.

## Decisions

- **Test format:** Farley's four layers: test cases in domain words, a
  DSL, protocol drivers, the system. Chosen once per project: plain code
  in the project's own test runner by default (no dependency, any
  language), or Gherkin when the partner wants it (the scenarios are the
  test cases, step definitions the DSL). Skills teach the pattern; each
  project grows its own DSL.
- **How the work is done is the workflow's:** tests first, outside-in
  from acceptance tests, test doubles only at boundaries and for
  collaborators that don't exist yet (made the ecosystem's way), unit
  tests green on every commit with acceptance tests in their own stage.
  The design doc's approaches are about the software, not these.
- **No ADRs.** Decisions stay in the design doc, as upstream. Nygard and
  Fowler would supersede a reversed decision explicitly; upstream lives
  with the drift, and so does the fork. A "Reversed by" line comes back
  only if a stale decision misleads a run.
- **One slice at a time.** Each behaviour is a slice, and exactly one
  acceptance test is red at a time (GOOS: a feature starts with one
  failing acceptance test; Specification by Example: agree all examples,
  automate them one by one). The first slice's test is written before
  approval. Each later slice's test is written when the slice starts,
  once the one before is green; the plan carries it as code, so the
  partner approves it with the plan. Edges are unit tests in the slice.
- **One spec approval.** The human partner approves the design doc and
  its first acceptance test together, then the plan. The doc already
  points to the test, and names the test each later slice will get.
- **Commit is approval.** The doc and tests are committed together.
  Committed test cases are read-only. New files are allowed. The DSL and
  drivers keep growing: drivers are plan tasks.
- **Right reason to fail.** A new DSL step fails with "not implemented",
  or doesn't exist yet when the acceptance tests compile apart from the
  unit tests: a compile error from code that doesn't exist yet is red, as
  long as the unit run still compiles. Real drivers are plan tasks, built
  under unit TDD.

## The workflow

1. `brainstorming`: as upstream, plus a Behaviours part in the design
   doc and the test format asked once per project. The builder check
   also asks: can each behaviour become a test? The hard gate points to `writing-acceptance-tests`.
2. `writing-acceptance-tests` (new): the first slice's behaviour becomes
   a test in domain words, through the DSL, in a stage of its own; the
   doc names the test each later slice will get. An architecture
   test for each decision that states a checkable structure. They fail
   for the right reason. The doc's behaviour lines then point to the
   tests (or say "no test").
3. Spec approval: the design doc and the first test together, one commit.
4. `writing-plans`: the header lists the spec and test files. The plan
   goes slice by slice: each later slice opens with a task that writes its
   test from the doc's example, in a new file. Each task names the
   acceptance tests it writes or advances; the plan says which task turns
   each one green. A case the spec leaves open where the human partner
   could want either outcome is a behaviour call: the plan doesn't decide
   it. The partner answers, it becomes an approved acceptance test, then
   execution starts. Robustness cases stay unit tests.
5. `test-driven-development`, `subagent-driven-development`,
   `executing-plans`: upstream, unchanged. Baselines showed no failure to
   fix. They still say "the spec is the binding authority"; no run has
   let the spec's prose overrule a test.
6. Change path: if a test looks wrong, stop and ask. Continue only after
   approval.
7. No hooks. Superpowers runs in many harnesses and skills can't
   enforce; blocking is the harness's job (obra on #1040). A final-review
   check that approved tests are unchanged waits for a run that changes
   one: so far none has.

## How we test it

Each skill change goes through `writing-skills`: baseline, change, pressure
test, then the next one. Fresh sessions against a fixture repo, 5 per arm,
every reply read by hand. Results go next to this file as
`…-eval-results.md`.

Then a real run: the Codurance Social Networking kata in Java (Maven),
then a change request. Comparing against other workflows comes after the
fork works.
