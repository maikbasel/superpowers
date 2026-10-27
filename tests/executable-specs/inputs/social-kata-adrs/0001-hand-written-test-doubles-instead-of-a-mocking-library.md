# 1. Test collaborators with hand-written fakes and spies, not a mocking library

Date: 2026-10-27
Status: Proposed

## Context

The kata is built outside-in: each test names the collaborators it needs as
interfaces, and the unit tests for a class replace those collaborators with
test doubles. Something has to supply those doubles. The usual London-school
tool is a mocking library such as Mockito. The project's test dependencies
are only JUnit 5.10.2, and there is no infrastructure that a tool would need
to stand in for.

## Decision

Doubles are small hand-written fakes and spies, written in the test sources
as plain Java implementing the collaborator interfaces. No mocking library
is added to `pom.xml`.

## Consequences

- No new dependency. The doubles read as ordinary Java.
- More test code: every collaborator interface needs its own fake or spy.
- Interactions are verified by inspecting what a spy recorded, not through
  a library's verification DSL.
- Mockito and similar libraries are ruled out for this project.

## Rejected options

- **Mock-driven outside-in with Mockito.** Your human partner prefers fakes
  to a mocking library, and it adds a dependency the project doesn't
  otherwise need.
- **Acceptance test plus tests with real objects (Chicago style).** Sturdier
  tests, but the design emerges from refactoring instead of being driven
  from the outside, so it isn't strict outside-in.
