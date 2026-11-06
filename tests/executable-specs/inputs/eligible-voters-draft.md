# Late joiners: show who may vote in a round (design)

## Intent
Late joiners keep trying to vote in rounds they can't vote in and only learn it from the refusal. Showing who may vote in an open round lets them see it before they try.

## Goals / non-goals / anti-goals
- Goal: anyone can ask an open round who may vote in it.
- Non-goal: changing who is eligible. The late-joiners rule stays as it is.
- Anti-goal: a list that disagrees with what the round accepts.

## Constraints
This extends the late-joiners feature (`docs/superpowers/specs/2026-10-22-late-joiners-design.md`, acceptance tests in `src/test/java/club/voting/acceptance/LateJoinersAcceptanceTest.java`), which is built and green. Eligibility is the round's snapshot from that feature. Acceptance tests go through the DSL in `acceptance/dsl`; drivers in `acceptance/drivers`.

## Approaches
- A. The round exposes its snapshot as a read-only list.
- B. The club recomputes eligibility from members on each request. Two places would then decide eligibility.
- Chosen: A (human partner's pick). One source of truth: the same snapshot that accepts and refuses votes.

## Behaviours
1. Asking an open round who may vote lists the members who joined before it opened and leaves out a member who joined after.
2. The list is in the order members joined. (My call.)

## Decided by the human partner
Approach A.

## Left to the builder
The DSL and driver method names, and how the list is returned.
