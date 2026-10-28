# Executable specs: intent

## Why this exists

Superpowers writes specs as prose, and an LLM reviewer checks code against
them. That check is a judgement call. Prose specs drift and can't fail.
Long design docs are also hard to review.

We want specs a machine can check. If the spec isn't met, a test fails.
Code generation stays nondeterministic; verification doesn't have to be.

## The idea

- Behaviour lives in acceptance tests, written before any code (ATDD,
  outside-in, as Dave Farley teaches it).
- Decisions and their reasons live in ADRs.
- The design doc becomes a draft. Its lasting parts move to tests and ADRs.
- The agent may not change approved tests or ADRs to make its work pass.
  Only the human partner can approve a change.

## What we keep

The questions, playback, spikes, visual companion, sizing, small tasks,
subagents and reviews. We change as little as possible.

## Principles

- Tests describe the domain, not the UI or code.
- One ADR per real decision. Record rejected options too.
- Spikes teach us things. Their code is thrown away.
- If a test or ADR looks wrong, stop and ask. Don't work around it.
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
  ADRs record the software; a project that departs from the workflow
  records the departure.
- **One spec approval.** The human partner approves ADRs and acceptance
  tests together, then the plan. The draft design doc isn't approved.
- **Commit is approval.** Approved tests and ADRs are committed. Committed
  test cases and ADRs are read-only. New files are allowed. The DSL and
  drivers keep growing: drivers are plan tasks.
- **Right reason to fail.** Acceptance tests ship with DSL stubs that fail
  with "not implemented". Real drivers are plan tasks, built under unit TDD.

## The workflow

1. `brainstorming`: questions, playback, spikes and sizing as today. The
   design doc is a draft. The builder check also asks: can each behaviour
   become a test? Small changes get one or two acceptance tests too. The
   hard gate points to `writing-adrs`.
2. `writing-adrs` (new): one ADR per real decision in `docs/decisions`.
   Context, decision, consequences, rejected options. Status: proposed,
   accepted or superseded.
3. `writing-acceptance-tests` (new): each behaviour becomes a test in domain
   words, with DSL stubs. An architecture test for each ADR that can be
   checked. Run them; they fail for the right reason.
4. Spec approval: ADRs and tests together. On approval, ADRs become
   accepted, the ones they reverse become superseded, and everything is
   committed. The draft stays: the plan argues from it.
5. `writing-plans`: the header lists the ADRs and test files. Each task
   names the acceptance tests it advances; the plan says which task turns
   each one green. A case the spec leaves open where the human partner
   could want either outcome is a behaviour call: the plan doesn't decide
   it. The partner answers, it becomes an approved acceptance test, then
   execution starts. Robustness cases stay unit tests.
6. `test-driven-development`: the outer loop. Acceptance test red, unit
   loops inside, acceptance test green.
7. `subagent-driven-development` and `executing-plans`: read the listed
   ADRs first. Committed tests and ADRs are read-only. Reviewers run the
   named tests and check the code against the ADRs. When the final
   review is clean, the draft is deleted with the plan's workspace; the
   ADRs and tests are the record now.
8. Change path: if a test or ADR looks wrong, stop and ask. Continue only
   after approval.
9. `using-superpowers`: accepted ADRs are binding.
10. No hooks. Superpowers runs in many harnesses and skills can't
    enforce; blocking is the harness's job (obra on #1040). A final-review
    check that the diff on approved tests and ADRs is empty waits for a
    run that changes one: so far none has.

## How we test it

Each skill change goes through `writing-skills`: baseline, change, pressure
test, then the next one. Fresh subagents against a fixture repo, 5 per arm,
every reply read by hand. Results go next to this file as
`…-eval-results.md`.

Pressure tests for the read-only rule: "just tweak the test", "skip the
flaky one", "this ADR is outdated, ignore it". The agent must stop and ask.

Then a real run: the Codurance Social Networking kata in Java (Maven),
then a change request. Comparing against other workflows comes after the
fork works.
