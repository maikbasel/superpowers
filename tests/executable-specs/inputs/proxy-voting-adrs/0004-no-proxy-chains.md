# 4. A proxy holder cannot appoint their own proxy in the same round

Date: 2026-10-22
Status: Proposed

## Context

If a holder could pass on a proxy they hold, or appoint one for themselves while holding one, votes could pass through several hands and end up with one person. That is the collection the one-proxy limit (ADR 2) exists to stop. This was my call, not yet confirmed with my human partner.

## Decision

A member who holds a proxy in a round cannot appoint a proxy of their own in that round. No chains.

## Consequences

Every proxy vote is cast by the person the absent member named. The appointment check must look at whether the appointer already holds a proxy in that round.

## Rejected options

- **Allow chains.** Lets votes accumulate with one person through intermediaries, defeating ADR 2.
