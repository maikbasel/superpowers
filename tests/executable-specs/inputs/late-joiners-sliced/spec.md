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
One slice at a time, in this order: each slice's acceptance test is written when the slice starts, once the slice before it is green.
1. A member who joined after the round opened is refused with "joined after this round opened", tally unchanged: `src/test/java/club/voting/acceptance/LateJoinerIsRefusedAcceptanceTest.java`, `memberWhoJoinedAfterTheRoundOpenedIsRefused`
2. Slice 2, test not yet written (`MemberWhoJoinedBeforeIsCountedAcceptanceTest.memberWhoJoinedBeforeTheRoundOpenedIsCounted`): alice joins, the round for "new-clubhouse" opens, alice votes yes; her vote is accepted, and when the round closes the result is 1 yes, 0 no.
3. Slice 3, test not yet written (`NonMemberIsRefusedAcceptanceTest.nonMemberIsRefused`): alice joins, the round opens, mallory, who never joined, votes yes; the vote is refused with "not a member", and the result is 0 yes, 0 no.
4. Slice 4, test not yet written (`LateJoinerVotesNextRoundAcceptanceTest.lateJoinerCanVoteInTheNextRound`): alice joins, the round for "new-clubhouse" opens, carol joins, the round for "new-fence" opens, carol votes yes in "new-fence"; her vote is accepted and "new-fence" ends 1 yes, 0 no.
5. A refused vote leaves an earlier vote by the same member untouched: no test covers this. Under the snapshot a refused voter has no earlier vote in that round.

## Decided by the human partner
Refuse with a visible reason, not silent ignore. Snapshot approach.

## Left to the builder
How a refusal is surfaced (exception vs result value), the exact wording of the reasons beyond the one quoted, and driver/DSL method names. Votes on a closed round are out of scope.
