# Proxy voting: design

Sizing: a small change (one new concept in `Club`/`Round`, a handful of rules). Short draft, no builder check.

## Intent and why
Members who travel miss rounds. A member can name another member to cast their vote for one round, so their voice still counts.

## Goals, non-goals, anti-goals
- Goals: absent members' votes count; the club can see how many votes came by proxy.
- Non-goals: standing proxies that last across rounds; withdrawing an appointment; changing the existing rule that votes are not refused after a round closes.
- Anti-goal: a few people collecting everyone's vote (this happened at another club). The one-proxy limit exists for this.

## Constraints
- Existing library in `club.voting` (`Club`, `Round`), JUnit acceptance tests through the DSL in `acceptance/dsl` and driver in `acceptance/drivers`.
- A proxy covers a single round only.

## Approaches
- A. Proxy as a vote attribute: `Round.vote` gains an optional "cast by" member. Smallest change, but the rules are checked at vote time and nobody can see appointments before voting.
- B. Proxy as its own record: a round keeps appointments (absent member to holder), checked when appointed; voting looks them up. More code, rules sit where they are decided, appointments visible before voting.
- Chosen: B (human partner's pick). The one-proxy limit is a rule about appointments, and they want visibility.
- Dropped: a standing-proxy registry on the club, since proxies are single-round.

## Behaviours
In `src/test/java/club/voting/acceptance/ProxyVotingAcceptanceTest.java`:
1. A member names a proxy; the holder casts their vote as well as their own: `holderCastsTheAbsentMembersVoteAsWellAsTheirOwn`
2. A member who already holds a proxy is refused a second: `memberWhoAlreadyHoldsAProxyIsRefusedASecondOne`
3. The absent member's own vote wins over the proxy vote: `absentMembersOwnVoteCountsWhenCastAfterTheProxyVote`, `proxyVoteIsDroppedWhenAbsentMemberAlreadyVoted`
4. The tally counts proxy votes and reports how many: `tallyCountsProxyVotesAndReportsHowManyCameByProxy`
5. Naming a proxy on a closed round is refused: `namingAProxyOnAClosedRoundIsRefused`

My calls (confirmed with the human partner at approval):
6. A proxy covers only its round: `proxyCoversOnlyTheRoundItWasNamedFor`
7. Naming yourself is refused: `namingYourselfAsProxyIsRefused`
8. Only members appoint or hold proxies: `nonMemberCannotHoldAProxy`, `nonMemberCannotAppointAProxy`
9. No chains: `proxyHolderCannotAppointTheirOwnProxyInTheSameRound`
10. A new appointment replaces the earlier one if the holder is free: `newAppointmentReplacesTheEarlierOne`, `replacementIsRefusedWhenTheNewHolderAlreadyHoldsAProxy`
11. A holder casts only for someone who named them: `holderCannotCastAProxyVoteForSomeoneWhoDidNotNameThem`
12. Only proxy votes in the tally count as proxy votes: `droppedProxyVoteIsNotCountedAsAProxyVote`

## How, as decided
- Appointments live with the round (approach B). Round validation of membership needs `Club` to supply membership: the builder's call how.

## Left to the builder
- Method names and signatures, how `Round` learns membership, how the tally exposes the proxy count (a new field on `Tally`), and the acceptance DSL wording.
