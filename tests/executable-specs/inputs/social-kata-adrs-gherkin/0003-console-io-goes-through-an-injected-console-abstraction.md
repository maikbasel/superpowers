# 3. Console input and output go through an injected console abstraction

Date: 2026-10-27
Status: Proposed

## Context

The app's only boundary is the console: it reads command lines and prints
prompts and results. The acceptance tests drive the whole app through that
boundary and assert the full output stream, prompts included.

## Decision

The app does not touch `System.in` or `System.out` directly. It receives a
console abstraction for reading lines and writing output, and only the
entry point wires it to the real streams. Tests supply a scripted console
that feeds input lines and captures output.

## Consequences

- Acceptance tests run the app in-process, with no real stdin/stdout.
- End of input is seen through the abstraction, so the run method can
  return normally at EOF.
- One more interface and a thin real implementation to maintain.
- Direct use of the standard streams inside the app is ruled out.

## Rejected options

- **Use `System.in` and `System.out` directly.** Tests would need to
  swap global streams or spawn a process, which is fragile and slow.
