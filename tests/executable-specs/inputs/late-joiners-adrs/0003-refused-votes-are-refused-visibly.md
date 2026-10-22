# 3. A refused vote is refused with a visible reason

Date: 2026-10-22

## Status

Proposed

## Context

Under ADR 2 some votes are refused. A refusal that silently disappears leaves the voter believing their vote counted, and a refused vote that still gets counted defeats the rule.

## Decision

A refused vote is reported to the caller with a reason and is not counted. An earlier vote by the same member stays untouched. How the refusal is surfaced is left to the builder.

## Consequences

The voter can be told why. Callers have to handle a refusal, which `Round.vote` did not have before. Every refusal needs a reason.

## Rejected options

- **Silently ignore the vote.** The voter cannot tell it was dropped, or why.
