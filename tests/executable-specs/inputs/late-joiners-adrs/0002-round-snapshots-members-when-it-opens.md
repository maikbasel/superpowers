# 2. A round snapshots its eligible members when it opens

Date: 2026-10-22

## Status

Proposed

Supersedes: 1

## Context

Someone could join the club just to sway a vote that is already running, so eligibility has to be fixed when a round opens. ADR 1 has `Round` accept a vote from anyone and leaves membership to the website. That cannot hold: the rule "joined after the round opened" is about the round, and the website does not know when each round opened. A vote from a person who is not a member at all now also has to be refused, because the snapshot is the only list of who may vote.

## Decision

When a round opens it copies the club's member list. `Round` refuses a vote from anyone not in that copy. A member who joins later is eligible in the next round opened after they joined.

## Consequences

The rule is stated directly and needs no clock. `Round` now knows about membership, so ADR 1's "library has no notion of membership" no longer holds, and calling the library directly can no longer vote without being a member. A round holds a copy of the member list for its lifetime. Someone who leaves the club mid-round can still vote in that round.

## Rejected options

- **Join times on `Club`, compared with the round's open time.** Needs a clock and more moving parts for the same rule.
- **Keep ADR 1 (website checks membership).** The website cannot tell who joined after a given round opened.
