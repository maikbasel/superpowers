---
name: writing-acceptance-tests
description: Use when a design doc's behaviours need to become acceptance tests before any code is written, or when your human partner approves the design doc and its acceptance tests
---

# Writing Acceptance Tests

Each behaviour in the design doc becomes an acceptance test, written
before any code. The tests say what done means; the design doc says why.

**Announce at start:** "I'm using the writing-acceptance-tests skill to
turn the behaviours into tests."

## The four layers

Plain code in the project's own test runner, unless the project's
acceptance tests or the design doc say Gherkin: then the feature files
are the test cases and the step definitions are the DSL.

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
- A decision in the design doc that states a checkable structure (a
  layer, a dependency rule, a boundary) gets an architecture test too.

## Their own stage

Unit tests run on every commit and stay green. Acceptance tests run in a
stage of their own, red until the task that owns them turns them green,
so they never break the commit build. If the project has no such stage
yet, set one up the build's usual way: in Maven, the Failsafe plugin and
`mvn verify`; in Gradle, a separate test task; in npm, a separate
script. Leave the unit run as it is.

## Fail for the right reason

Run the acceptance stage. Every new test fails, and every failure says
"not implemented". Existing tests still pass, and the unit run is green.

| You see | Fix |
|---------|-----|
| Doesn't compile | A step calls the system. Make it a stub. |
| Fails on an assertion | A step reached the system. Make it a stub. |
| Passes | The test is missing its new step, or the behaviour already holds. Tell your human partner which. |

## Point the design doc at the tests

Replace each behaviour line in the design doc with the test that covers
it, by file and name. A behaviour no test covers says so. Leave the rest
of the doc as it is: intent, goals, decisions, constraints. The tests
bind what the software does; the doc keeps the why.

## Spec approval

Don't commit yet. A commit is the approval.

Ask your human partner to approve the spec: the design doc and the
acceptance tests together. Say which test covers which behaviour, and
which calls in the doc are your own (the doc records who picked what;
check it). Changes go back through this skill, then you ask again.

**On approval**, commit the design doc, test cases and DSL stubs
together, in one commit.

Then invoke superpowers:writing-plans and no other skill.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll wire the driver so the test is real" | A driver is a plan task. Stub the DSL step. |
| "An assertion failure is a better red" | It means the test reached the system. Stub it. |
| "This test passes already, good" | Then it tests nothing new. Find the missing step. |
| "It fits in the existing test file" | Committed test cases are read-only. New file. |
| "The method doesn't exist yet, that's red enough" | A compile error isn't a failing test. Stub it. |
| "Commit the tests so they're safe" | A commit is the approval. Wait for it. |
| "Red tests in the unit run are fine until it's built" | Every commit is red then. Give them their own stage. |
| "I wrote it down, so it's my call" | Writing it isn't choosing it. The doc says who picked what. |
| "The behaviour lines read better, keep them" | Two copies drift. Point to the test. |
