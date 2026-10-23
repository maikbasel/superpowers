# Late Joiners Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A round fixes its eligible voters when it opens, and refuses (with a visible reason, uncounted) any vote from someone not in that list.

**Architecture:** `Club.openRound` hands the new `Round` a copy of the member set plus a live "is this person a club member now" check. `Round.vote` returns a `VoteResult` instead of `void`; a refusal carries a reason and leaves the votes map untouched. The test driver records each vote's result so the DSL can assert on it.

**Tech Stack:** Java 21, Maven, JUnit 5.10.2.

**Spec:** `docs/superpowers/specs/2026-10-22-late-joiners-design.md`

**ADRs:** `docs/decisions/0002-round-snapshots-members-when-it-opens.md`, `docs/decisions/0003-refused-votes-are-refused-visibly.md` (ADR 0001 is superseded; do not follow it).

**Acceptance tests:** `src/test/java/club/voting/acceptance/LateJoinersAcceptanceTest.java`, `src/test/java/club/voting/acceptance/VotingAcceptanceTest.java`. Read-only: no task edits them. The DSL and driver under `acceptance/dsl` and `acceptance/drivers` are support code and Task 2 does edit them.

## Global Constraints

- Java release 21 (`maven.compiler.release`), JUnit 5.10.2, no new dependencies.
- Refusal reasons, verbatim: `"joined after this round opened"` and `"not a member"`.
- Out of scope: tallying, closing, round lookup, votes on a closed round.

## Review Focus

1. A `null` member name votes: refused with "not a member", no exception, tally unchanged.
2. A club with no members opens a round: every vote is refused "not a member".
3. A late joiner votes repeatedly: every attempt is refused, and the tally never moves.
4. A refused vote must not disturb other members' votes (spec behaviour 5, scoped to what the code can do: no leave operation exists, so an eligible member is never refused after voting).

## Behaviour calls

None.

---

### Task 1: Round enforces its snapshot

**Files:**
- Modify: `src/main/java/club/voting/Round.java`
- Modify: `src/main/java/club/voting/Club.java`
- Create: `src/test/java/club/voting/unit/RoundEligibilityTest.java`
- Modify: `src/test/java/club/voting/unit/RoundTest.java` (alice must join the club before the round opens, since non-members are now refused)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `public record Round.VoteResult(boolean accepted, String reason)` with static factories `VoteResult.accepted()` (reason `null`) and `VoteResult.refused(String reason)`.
  - `public Round.VoteResult Round.vote(String member, boolean yes)` (was `void`).
  - `Round(String proposal, Set<String> eligibleMembers, Predicate<String> isCurrentMember)` (package-private; stores a copy of the set).

**Acceptance tests:** `VotingAcceptanceTest.resultCountsEachMembersVote` (already green; must stay green, no driver change needed yet).

- [ ] **Step 1: Write the failing tests** in `RoundEligibilityTest` (build rounds via `Club`):
  - `memberInSnapshotIsAccepted`: alice joins, round opens, `vote("alice", true)` → `accepted()` true, `reason()` null, `tally()` = (1, 0).
  - `joinedAfterOpenIsRefusedWithReason`: round opens, carol joins, `vote("carol", false)` → not accepted, reason `"joined after this round opened"`, tally (0, 0).
  - `nonMemberIsRefusedWithReason`: `vote("mallory", true)` → reason `"not a member"`, tally (0, 0).
  - `nullMemberIsRefused` (Review Focus 1): `vote(null, true)` → reason `"not a member"`, no exception.
  - `emptyClubRefusesEveryone` (Review Focus 2): round opened with no members, `vote("alice", true)` → reason `"not a member"`.
  - `repeatedLateVotesNeverCount` (Review Focus 3): carol joins late, votes yes then no → both refused, tally (0, 0).
  - `refusedVoteLeavesOtherVotesUntouched` (Review Focus 4): alice votes yes, late carol refused → tally (1, 0).
  - `nextRoundSnapshotIncludesEarlierLateJoiner`: carol joins after round A opens; round B opened afterwards accepts her vote.
  - In `RoundTest.laterVoteReplacesEarlierVote`, add `club.join("alice")` before `openRound` (keep its assertions).
- [ ] **Step 2: Run** `mvn test -Dtest='RoundEligibilityTest,RoundTest'`. Expected: compile failure / FAIL (`VoteResult` undefined).
- [ ] **Step 3: Implement** `Round.VoteResult` and `Round.vote` per Interfaces. Eligible if `member` is in the snapshot (null-safe: use a copy that tolerates `null` lookups, e.g. `Set.copyOf` rejects null elements but `contains(null)` throws, so check `member != null` first). Otherwise refuse with "joined after this round opened" when `isCurrentMember.test(member)`, else "not a member". Refusals do not touch `votes`.
- [ ] **Step 4: Implement** `Club.openRound`: pass `Set.copyOf(members)` and `this::isMember` to the new `Round` constructor (`isMember` must handle `null` without throwing; `HashSet.contains(null)` is fine).
- [ ] **Step 5: Run** `mvn test`. Expected: all unit tests PASS; `VotingAcceptanceTest` PASS; the four `LateJoinersAcceptanceTest` tests still FAIL ("not implemented").
- [ ] **Step 6: Commit**

```bash
git add src/main src/test/java/club/voting/unit
git commit -m "feat: round snapshots members and refuses ineligible votes"
```

### Task 2: Driver and DSL surface refusals

**Files:**
- Modify: `src/test/java/club/voting/acceptance/drivers/LibraryDriver.java`
- Modify: `src/test/java/club/voting/acceptance/dsl/VotingDsl.java`

**Interfaces:**
- Consumes: `Round.vote(String, boolean)` returning `Round.VoteResult(boolean accepted, String reason)`.
- Produces:
  - `LibraryDriver.vote(String member, String proposal, boolean yes)` now stores the returned `VoteResult` keyed by member and proposal (latest wins).
  - `LibraryDriver.lastVoteResult(String member, String proposal): Round.VoteResult`.
  - `VotingDsl.assertVoteRefused(member, proposal, reason)`: asserts the stored result is not accepted and its reason equals `reason`.
  - `VotingDsl.assertVoteAccepted(member, proposal)`: asserts the stored result is accepted. Both fail with a clear message if no vote was cast.

**Acceptance tests:**
- `LateJoinersAcceptanceTest.memberWhoJoinedAfterTheRoundOpenedIsRefused`
- `LateJoinersAcceptanceTest.memberWhoJoinedBeforeTheRoundOpenedIsCounted`
- `LateJoinersAcceptanceTest.nonMemberIsRefused`
- `LateJoinersAcceptanceTest.lateJoinerCanVoteInTheNextRound`

- [ ] **Step 1: Run** `mvn test -Dtest=LateJoinersAcceptanceTest`. Expected: the four tests FAIL with "not implemented" (the failing test already exists and is approved).
- [ ] **Step 2: Implement** the driver storage and `lastVoteResult` as in Interfaces.
- [ ] **Step 3: Implement** the two DSL assertions, replacing the `UnsupportedOperationException` stubs.
- [ ] **Step 4: Run** `mvn test`. Expected: every test PASS, including all four above and `VotingAcceptanceTest`.
- [ ] **Step 5: Commit**

```bash
git add src/test/java/club/voting/acceptance/drivers src/test/java/club/voting/acceptance/dsl
git commit -m "test: driver and DSL report vote refusals"
```

## Self-Review notes

- Spec behaviours 1–4 map to Task 2's four acceptance tests, backed by Task 1 unit tests. Behaviour 5 has no acceptance test; Task 1's `refusedVoteLeavesOtherVotesUntouched` pins what the code can express.
- Every approved test is named by exactly one task (5 tests: 1 in Task 1, 4 in Task 2).
- Refusal surfaced as a result value (left to the builder by ADR 3); `Round.vote`'s one other caller is the driver.
