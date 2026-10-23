# Late Joiners Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A round fixes its eligible voters when it opens; any vote from someone outside that set is refused with a visible reason and not counted.

**Architecture:** `Club.openRound` copies the member set into the new `Round`. `Round.vote` returns a `VoteResult` (accepted, or refused with a reason) instead of `void`. To tell "joined after" from "not a member", the round also keeps a live view of the club's current membership. The acceptance driver records each vote's result so the DSL can assert on it.

**Tech Stack:** Java 21, Maven, JUnit 5.10.2 (`mvn test`).

**Spec:** `docs/superpowers/specs/2026-10-22-late-joiners-design.md`

**ADRs:** `docs/decisions/0002-round-snapshots-members-when-it-opens.md`, `docs/decisions/0003-refused-votes-are-refused-visibly.md` (ADR 0001 is superseded by 0002; do not follow it).

**Acceptance tests:** `src/test/java/club/voting/acceptance/LateJoinersAcceptanceTest.java`, `src/test/java/club/voting/acceptance/VotingAcceptanceTest.java`. Read-only: no task edits them. If one needs changing, stop and ask the human partner. (The DSL and driver under `acceptance/dsl` and `acceptance/drivers` are not test files; Task 2 implements their stubs.)

## Global Constraints

- Java release 21 (`maven.compiler.release` in `pom.xml`); no new dependencies.
- Refusal reasons, verbatim: `joined after this round opened` (joined the club after this round opened); `not a member` (not in the club at all).
- A refused vote is never counted and leaves an earlier vote by the same member untouched.
- Out of scope (spec): tallying, closing, round lookup, votes on a closed round. Do not change them.

## Review Focus

- `vote(null, ...)`: must be refused as `not a member`, not throw. Pinned in Task 1 (`Set.copyOf(...).contains(null)` throws, so copy with `new HashSet<>(...)`).
- A name differing only by case (`"Alice"` vs `"alice"`): a different person, refused as `not a member`. Pinned in Task 1.
- A round opened while the club has no members: every vote refused, tally 0/0, no exception. Pinned in Task 1.
- Re-opening the same proposal name: the new round gets a fresh snapshot, so a member who joined between the two openings can vote in the second. Pinned in Task 1.
- The existing `RoundTest.laterVoteReplacesEarlierVote` votes as a non-member; under ADR 2 it would be refused and fail. Task 1 fixes it by joining the voter first.

---

### Task 1: Snapshot eligibility and visible refusals in `Round`/`Club`

**Files:**
- Create: `src/main/java/club/voting/VoteResult.java`
- Modify: `src/main/java/club/voting/Round.java`, `src/main/java/club/voting/Club.java`
- Test: `src/test/java/club/voting/unit/RoundTest.java`

**Interfaces:**
- Consumes: existing `Club.join(String)`, `Club.isMember(String)`, `Club.openRound(String)`.
- Produces:
  - `public sealed interface VoteResult permits VoteResult.Accepted, VoteResult.Refused` with `record Accepted() implements VoteResult` and `record Refused(String reason) implements VoteResult`, in `club.voting`.
  - `public VoteResult Round.vote(String member, boolean yes)` (was `void`).
  - `Round` constructor becomes package-private `Round(String proposal, Set<String> eligible, Predicate<String> currentlyMember)`; `Club.openRound(String)` keeps its signature and passes `new HashSet<>(members)` and `this::isMember`.

**Acceptance tests:** none (Task 2 turns the acceptance tests green).

- [ ] **Step 1: Write the failing tests in `RoundTest`**

First fix `laterVoteReplacesEarlierVote`: create `var club = new Club(); club.join("alice");` before `club.openRound("p")`. Then add these tests, each with a `Club`, asserting on the `round.vote(...)` result and `round.tally()`:
  - `memberInSnapshotIsAccepted`: join alice, open; `vote("alice", true)` equals `new VoteResult.Accepted()`; `tally().yes()==1`.
  - `joinedAfterOpenIsRefusedWithReason`: join alice, open, join carol; `vote("carol", false)` equals `new VoteResult.Refused("joined after this round opened")`; `tally().no()==0`.
  - `nonMemberIsRefusedWithReason`: `vote("mallory", true)` equals `new VoteResult.Refused("not a member")`; tally 0/0.
  - `refusedVoteLeavesEarlierVoteUntouched`: alice votes yes (accepted), carol (late) votes no (refused); tally `yes()==1, no()==0`.
  - `nullMemberIsRefusedAsNotAMember`: `vote(null, true)` equals `Refused("not a member")`.
  - `differentCaseIsADifferentPerson`: join "alice"; `vote("Alice", true)` equals `Refused("not a member")`.
  - `emptyClubRefusesEveryone`: open with no members; `vote("alice", true)` is `Refused("not a member")`; tally 0/0.
  - `reopenedProposalTakesAFreshSnapshot`: join alice, open "p", join carol, open "p" again; `club.round("p").vote("carol", true)` equals `Accepted`.

- [ ] **Step 2: Run to verify failure**

Run: `mvn -q test -Dtest=RoundTest`
Expected: compilation FAIL (`VoteResult` not defined).

- [ ] **Step 3: Implement**

Create `VoteResult` as specified. In `Round`, store `eligible` and `currentlyMember`. `vote` records the vote and returns `Accepted` if `eligible.contains(member)`; otherwise it records nothing and returns `Refused("joined after this round opened")` if `currentlyMember.test(member)`, else `Refused("not a member")`. `Club.openRound` builds the round as in Interfaces.

- [ ] **Step 4: Run to verify pass**

Run: `mvn -q test -Dtest=RoundTest`
Expected: PASS (9 tests).

- [ ] **Step 5: Commit**

```bash
git add src/main/java/club/voting src/test/java/club/voting/unit/RoundTest.java
git commit -m "feat: round snapshots members on open and refuses ineligible votes with a reason"
```

### Task 2: Surface vote results through driver and DSL

**Files:**
- Modify: `src/test/java/club/voting/acceptance/drivers/LibraryDriver.java`, `src/test/java/club/voting/acceptance/dsl/VotingDsl.java`
- Test: `src/test/java/club/voting/acceptance/LateJoinersAcceptanceTest.java` (read-only; run, do not edit)

**Interfaces:**
- Consumes: `VoteResult` and `Round.vote(String, boolean)` from Task 1.
- Produces: `LibraryDriver.vote(String member, String proposal, boolean yes)` stays `void` and records the result; new `LibraryDriver.lastVoteResult(String member, String proposal) -> VoteResult` (most recent result for that pair; `IllegalStateException` if that member never voted on that proposal). The DSL's `assertVoteRefused(member, proposal, reason)` and `assertVoteAccepted(member, proposal)` use it.

**Acceptance tests:** `LateJoinersAcceptanceTest.memberWhoJoinedAfterTheRoundOpenedIsRefused`, `LateJoinersAcceptanceTest.memberWhoJoinedBeforeTheRoundOpenedIsCounted`, `LateJoinersAcceptanceTest.nonMemberIsRefused`, `LateJoinersAcceptanceTest.lateJoinerCanVoteInTheNextRound`. (`VotingAcceptanceTest.resultCountsEachMembersVote` already passes and must stay green.)

- [ ] **Step 1: Run the acceptance tests to see them fail**

Run: `mvn -q test -Dtest=LateJoinersAcceptanceTest`
Expected: 4 errors, "not implemented: assertVoteRefused / assertVoteAccepted".

- [ ] **Step 2: Implement `lastVoteResult` in `LibraryDriver`**

Keep a map keyed by member and proposal; `vote` stores what `round.vote` returned. The driver must not throw on a refusal: the tests call `memberVotes` before asserting.

- [ ] **Step 3: Implement the DSL assertions in `VotingDsl`**

`assertVoteRefused`: assert `driver.lastVoteResult(member, proposal)` equals `new VoteResult.Refused(reason)`. `assertVoteAccepted`: assert it equals `new VoteResult.Accepted()`. Remove the `UnsupportedOperationException` bodies.

- [ ] **Step 4: Run the whole suite**

Run: `mvn -q test`
Expected: PASS, no failures (RoundTest 9, LateJoinersAcceptanceTest 4, VotingAcceptanceTest 1).

- [ ] **Step 5: Commit**

```bash
git add src/test/java/club/voting/acceptance/drivers src/test/java/club/voting/acceptance/dsl
git commit -m "test: implement vote-result assertions in driver and DSL"
```

## Self-review notes

- Spec behaviours 1-4 are covered by Task 2's acceptance tests and Task 1's unit tests. Behaviour 5 is unit-tested only: no approved acceptance test builds that scenario.
- Each `LateJoinersAcceptanceTest` test is named by Task 2 only.
- Left as-is (spec: out of scope): votes on a closed round are still accepted; `club.round(unknownProposal)` still returns null.
