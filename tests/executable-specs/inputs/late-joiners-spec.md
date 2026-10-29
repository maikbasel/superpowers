# Late joiners can't vote in an open round (design)

## Intent
Eligibility for a round is fixed when it opens, so nobody can join the club just to sway a vote already running.

## Goals / non-goals / anti-goals
- Goal: a member who joined after a round opened cannot vote in it, and is told why.
- Non-goal: changing tallying, closing, or how rounds are looked up.
- Anti-goal: a refused vote that silently disappears or still gets counted.

## Constraints
Existing code: `Club` keeps a member set; `Round.vote` accepts anyone and checks neither membership nor closed state. Acceptance tests go through the DSL in `acceptance/dsl`; drivers in `acceptance/drivers`.

## Approaches
- A. Snapshot: a round copies the member list when it opens; a vote from anyone not in it is refused.
- B. Join times: `Club` records join times and a vote compares them to the round's open time. Needs a clock and more moving parts for the same rule.
- Chosen: A (human partner's pick). It states the rule directly and needs no clock.

## Behaviours
In `src/test/java/club/voting/acceptance/LateJoinersAcceptanceTest.java`:
1. A member who joined after the round opened is refused with "joined after this round opened", tally unchanged: `memberWhoJoinedAfterTheRoundOpenedIsRefused`
2. A member who joined before the round opened is counted: `memberWhoJoinedBeforeTheRoundOpenedIsCounted`
3. A non-member is refused ("not a member") and not counted: `nonMemberIsRefused`
4. A member who joined mid-round can vote in the next round: `lateJoinerCanVoteInTheNextRound`
5. A refused vote leaves an earlier vote by the same member untouched: no test covers this. Under the snapshot a refused voter has no earlier vote in that round.

## Decided by the human partner
Refuse with a visible reason, not silent ignore. Snapshot approach.

## Left to the builder
How a refusal is surfaced (exception vs result value), the exact wording of the reasons beyond the one quoted, and driver/DSL method names. Votes on a closed round are out of scope.
