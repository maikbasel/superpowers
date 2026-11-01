package club.voting.acceptance;

import club.voting.acceptance.dsl.VotingDsl;
import org.junit.jupiter.api.Test;

class LateJoinerIsRefusedAcceptanceTest {
    private final VotingDsl voting = new VotingDsl();

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
}
