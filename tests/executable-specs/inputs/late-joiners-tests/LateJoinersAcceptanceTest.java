package club.voting.acceptance;

import club.voting.acceptance.dsl.VotingDsl;
import org.junit.jupiter.api.Test;

class LateJoinersAcceptanceTest {
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

    @Test
    void memberWhoJoinedBeforeTheRoundOpenedIsCounted() {
        voting.memberJoins("alice");
        voting.roundOpensFor("new-clubhouse");
        voting.memberVotes("alice", "new-clubhouse", "yes");
        voting.assertVoteAccepted("alice", "new-clubhouse");
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

    @Test
    void lateJoinerCanVoteInTheNextRound() {
        voting.memberJoins("alice");
        voting.roundOpensFor("new-clubhouse");
        voting.memberJoins("carol");
        voting.roundOpensFor("new-fence");
        voting.memberVotes("carol", "new-fence", "yes");
        voting.assertVoteAccepted("carol", "new-fence");
        voting.roundClosesFor("new-fence");
        voting.assertResult("new-fence", 1, 0);
    }
}
