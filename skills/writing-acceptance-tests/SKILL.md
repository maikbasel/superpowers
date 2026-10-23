---
name: writing-acceptance-tests
description: Use when a design draft's behaviours need to become acceptance tests before any code is written, or when your human partner approves ADRs and acceptance tests
---

# Writing Acceptance Tests

Each behaviour in the draft becomes an acceptance test, written before any
code. The tests are the spec: once approved, they say what done means.

**Announce at start:** "I'm using the writing-acceptance-tests skill to
turn the behaviours into tests."

## The four layers

Plain code in the project's own test runner. No Gherkin.

1. **Test cases** in domain words. They say what happens, never how the
   system is reached. No classes, endpoints or screens.
2. **The DSL**: the domain steps the test cases call.
3. **Drivers**: how the DSL reaches the system (API, HTTP, UI).
4. **The system.**

Use the project's DSL and add the steps you need. If there is none, start
one next to the tests.

## Write

- One test per behaviour line, more when a behaviour has edges. Name each
  after the behaviour.
- New test cases go in a new file. Committed test cases are approved and
  read-only, even to add a test next to them.
- Every new DSL step is a stub that fails with "not implemented", e.g.
  `throw new UnsupportedOperationException("not implemented: <step>")`.
- Leave drivers and production code alone. How a step reaches the system
  is the builder's call, and a plan task.
- An ADR that states a checkable structure (a layer, a dependency rule, a
  boundary) gets an architecture test too.

## Fail for the right reason

Run the tests. Every new test fails, and every failure says "not
implemented". Existing tests still pass.

| You see | Fix |
|---------|-----|
| Doesn't compile | A step calls the system. Make it a stub. |
| Fails on an assertion | A step reached the system. Make it a stub. |
| Passes | The test is missing its new step, or the behaviour already holds. Tell your human partner which. |

## Spec approval

Don't commit yet. A commit is the approval.

Ask your human partner to approve the spec: the ADRs and the acceptance
tests together. Say which test covers which behaviour, which ADRs are your
own calls (the draft records who picked what; check it), and which
earlier ADR any of them reverses. Changes go back
through this skill, then you ask again.

**On approval**, one commit:

1. Each new ADR: `Status: Accepted`.
2. Each ADR named under `Supersedes:` in them: `Status: Superseded by M`.
   Nothing else in it changes.
3. Commit the ADRs, test cases and DSL stubs together.

Leave the draft where it is. The plan argues from it.

Then invoke superpowers:writing-plans and no other skill.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll wire the driver so the test is real" | A driver is a plan task. Stub the DSL step. |
| "An assertion failure is a better red" | It means the test reached the system. Stub it. |
| "This test passes already, good" | Then it tests nothing new. Find the missing step. |
| "It fits in the existing test file" | Committed test cases are read-only. New file. |
| "The method doesn't exist yet, that's red enough" | A compile error isn't a failing test. Stub it. |
| "0001 is still Accepted, so leave it" | The new ADR supersedes it. Mark it on approval. |
| "Commit the tests so they're safe" | A commit is the approval. Wait for it. |
| "I wrote the ADR, so it's my call" | Writing it isn't choosing it. The draft says who picked what. |
