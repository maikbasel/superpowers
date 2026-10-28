# 4. Acceptance tests are written in Gherkin and run with Cucumber

Date: 2026-10-27
Status: Proposed

## Context

The human partner wants to review the acceptance tests as plain text,
without reading Java. The workflow's default is a code DSL in the
project's own test runner; this project departs from it.

## Decision

Acceptance tests are Gherkin `.feature` files run by Cucumber for Java on
the JUnit Platform. Step definitions are the DSL layer; they call drivers,
which reach the system.

## Consequences

- Scenarios read as plain text, so the partner can approve them directly.
- A Cucumber dependency, and glue code between step text and Java.
- Step text and step definitions can drift apart; an undefined step must
  fail the run, not be skipped.

## Rejected options

- **Code DSL in JUnit (the workflow default).** No dependency and fully
  refactorable, but the partner would approve Java code instead of text.
