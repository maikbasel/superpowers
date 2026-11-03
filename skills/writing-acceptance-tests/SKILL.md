---
name: writing-acceptance-tests
description: Use when a design doc's behaviours need to become acceptance tests before any code is written, or when your human partner approves the design doc and its acceptance tests
---

# Writing Acceptance Tests

Each behaviour in the design doc becomes an acceptance test, one slice
at a time, written before its code. The tests say what done means; the
design doc says why.

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

## One slice at a time

Each behaviour line is a slice: one end-to-end increment. Exactly one
acceptance test is red at a time.

- Order the slices: first the one the others build on, usually the
  first line.
- Write the acceptance test for the first slice now, and only that one.
- Every later slice gets its test when it starts, once the slice before
  it is green. writing-plans puts that test, as code, at the start of
  the slice's tasks, so your human partner approves it with the plan.
- A behaviour's edges and robustness cases are unit tests inside its
  slice, not more acceptance tests.

## Write

- One test, for the first slice. Name it after the behaviour.
- Group test cases by feature: one file per feature, named after it,
  like the scenarios of one Gherkin feature file. A new feature gets a
  new file; a new behaviour of an existing feature goes next to its
  siblings. Approved test cases are frozen: their steps and what they
  check change only when the requirement changes, never to make them
  pass. Adding a test case beside them leaves them as they are. Keep
  setup, waits and other plumbing in the DSL and drivers, so an approved
  test case never needs editing.
- A new DSL step is missing or a stub that fails with "not implemented",
  e.g. `throw new UnsupportedOperationException("not implemented: <step>")`.
  If the acceptance tests compile on their own (their own source set or
  module), a step that doesn't exist yet is fine. If they compile with
  the unit tests, a missing step breaks the unit run: stub it.
- Leave drivers and production code alone. How a step reaches the system
  is the builder's call, and the slice's first plan task (see Fail for
  the right reason).
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

Approval is about the wording, so nothing has to run yet. Only the unit
run has to stay green, so the approval commit doesn't break the build.

The red that matters belongs to the slice's first plan task, after
approval. That task implements the drivers and only
the production entry points they need to compile and run (a signature,
an empty screen, a function that does nothing yet). For the first slice
of a project this is the walking skeleton: the thinnest path through
build, deploy and test. Then it runs the acceptance stage and sees the
test reach the system and fail on an assertion whose message names the
missing behaviour ("no alarm screen within 10 s"). A failure inside a
driver, a timeout with no message, or "not implemented" isn't it: fix the
driver or the diagnostic first. No behaviour gets built before this red
is seen.

## Point the design doc at the tests

Replace the first slice's behaviour line with its test, by file and
name. Every later line keeps its example and gets its slice number and
the file and name its test will have: "Slice 2, test not yet written
(`MemberIsCountedAcceptanceTest.memberIsCounted`): …". A behaviour no
test will cover says so. Leave the rest of the doc as it is: intent,
goals, decisions, constraints. The tests bind what the software does;
the doc keeps the why.

## Spec approval

Don't commit yet. A commit is the approval.

Ask your human partner to approve the spec: the design doc, with the
slices in order, and the first slice's acceptance test together. Say
which test covers which behaviour, and which calls in the doc are your
own (the doc records who picked what; check it). Changes go back
through this skill, then you ask again.

**On approval**, commit the design doc, the test case and its DSL
steps together, in one commit.

Then invoke superpowers:writing-plans and no other skill.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll write all the tests now, while the behaviours are fresh" | One red at a time. The examples are in the doc; later tests go in the plan. |
| "This edge case needs its own acceptance test" | Edges are unit tests in the slice. |
| "I'll wire the driver so the test is real" | Not before approval. Drivers are the slice's first plan task. Stub the DSL step. |
| "I'll run it now to see it red" | Approval is about the wording. The first plan task runs it, against real drivers. |
| "It failed on 'not implemented', so the test is proven" | The test is proven when it fails on a missing-behaviour assertion. |
| "This test passes already, good" | Then it tests nothing new. Find the missing step. |
| "While I add mine, I'll tidy the approved test next to it" | Add yours; leave theirs exactly as approved. Only a changed requirement changes it. |
| "The test needs a setup tweak to pass" | Plumbing goes in the DSL or a driver. The test case stays as approved. |
| "This assertion is too strict, loosen it" | Only a changed requirement changes a test case. Ask your human partner. |
| "A missing step can't hurt" | Only if the unit run still compiles. Check it. |
| "Commit the tests so they're safe" | A commit is the approval. Wait for it. |
| "Red tests in the unit run are fine until it's built" | Every commit is red then. Give them their own stage. |
| "I wrote it down, so it's my call" | Writing it isn't choosing it. The doc says who picked what. |
| "The behaviour lines read better, keep them" | Two copies drift. Point to the test once it exists. |
