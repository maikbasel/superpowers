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
}
