package club.voting.acceptance;

import club.voting.acceptance.dsl.VotingDsl;
import org.junit.jupiter.api.Test;

class VotingAcceptanceTest {
    private final VotingDsl voting = new VotingDsl();

    @Test
    void resultCountsEachMembersVote() {
        voting.memberJoins("alice");
        voting.memberJoins("bob");
        voting.roundOpensFor("new-clubhouse");
        voting.memberVotes("alice", "new-clubhouse", "yes");
        voting.memberVotes("bob", "new-clubhouse", "no");
        voting.roundClosesFor("new-clubhouse");
        voting.assertResult("new-clubhouse", 1, 1);
    }

    @Test
    void memberWhoJoinedAfterTheRoundOpenedIsRefused() {
        voting.memberJoins("alice");
        voting.roundOpensFor("new-clubhouse");
        voting.memberJoins("carol");
        voting.memberVotes("alice", "new-clubhouse", "yes");
        voting.memberVotes("carol", "new-clubhouse", "no");
        voting.assertVoteRefused("carol", "new-clubhouse", "joined after this round opened");
        voting.roundClosesFor("new-clubhouse");
        voting.assertResult("new-clubhouse", 1, 0);
    }

    @Test
    void nonMemberIsRefused() {
        voting.memberJoins("alice");
        voting.roundOpensFor("new-clubhouse");
        voting.memberVotes("mallory", "new-clubhouse", "yes");
        voting.assertVoteRefused("mallory", "new-clubhouse", "not a member");
        voting.roundClosesFor("new-clubhouse");
        voting.assertResult("new-clubhouse", 0, 0);
    }
}
