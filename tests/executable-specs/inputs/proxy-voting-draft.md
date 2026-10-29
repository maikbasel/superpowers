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
Said by the human partner:
1. A member names another member as their proxy for a round; the holder then casts that member's vote as well as their own.
2. A member who already holds a proxy in that round is refused a second one.
3. If the absent member votes themselves, their own vote counts and the proxy's vote for them is dropped (whichever is cast first).
4. The tally counts proxy votes like any other vote, and also reports how many of them came by proxy.
5. A proxy must be named before the round closes; naming one on a closed round is refused.

My calls (not yet confirmed with the human partner):
6. A proxy covers only the round it was named for; the holder has no say in other rounds' votes for that member.
7. Naming yourself as your proxy is refused.
8. Only club members can appoint or hold a proxy; naming a non-member is refused.
9. A member who holds a proxy cannot appoint their own proxy in the same round (no chains).
10. Naming a new proxy for the same absent member replaces the earlier appointment, as long as the new holder is free.
11. A holder can cast the proxy vote only for someone who named them; casting for anyone else is refused.
12. The proxy count counts only proxy votes that are in the tally (a dropped proxy vote does not count).

## How, as decided
- Appointments live with the round (approach B). Round validation of membership needs `Club` to supply membership: the builder's call how.

## Left to the builder
- Method names and signatures, how `Round` learns membership, how the tally exposes the proxy count (a new field on `Tally`), and the acceptance DSL wording.
