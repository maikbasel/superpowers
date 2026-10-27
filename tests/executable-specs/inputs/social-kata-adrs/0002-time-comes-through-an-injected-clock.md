# 2. Time comes through an injected clock abstraction

Date: 2026-10-27
Status: Proposed

## Context

Every post is stamped with the moment it was entered, and reading or the
wall shows "N minutes ago" relative to the moment the command is entered.
Tests must check output such as `5 minutes ago` and `1 minute ago` exactly,
and must be able to read the same post again 2 minutes later.

## Decision

The app never reads the system time itself. It receives a clock abstraction
and asks it for the current time whenever a command is entered. Tests supply
a controllable clock.

## Consequences

- Acceptance and unit tests are deterministic and need no sleeping.
- Tests can advance time between commands to show relative times.
- Production wiring must supply a real clock at the entry point.
- Code that calls the system clock directly is ruled out.

## Rejected options

- **Read the system clock directly.** Tests would be flaky or unable to
  assert exact relative times.
