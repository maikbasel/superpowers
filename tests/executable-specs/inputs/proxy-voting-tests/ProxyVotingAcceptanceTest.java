package club.voting.acceptance;

import club.voting.acceptance.dsl.VotingDsl;
import org.junit.jupiter.api.Test;

class ProxyVotingAcceptanceTest {
    private final VotingDsl voting = new VotingDsl();

    private void clubWithOpenRound(String... members) {
        for (String member : members) voting.memberJoins(member);
        voting.roundOpensFor("new-clubhouse");
    }

    // 1
    @Test
    void holderCastsTheAbsentMembersVoteAsWellAsTheirOwn() {
        clubWithOpenRound("alice", "bob");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.memberVotes("bob", "new-clubhouse", "yes");
        voting.proxyVotes("bob", "alice", "new-clubhouse", "no");
        voting.roundClosesFor("new-clubhouse");
        voting.assertResult("new-clubhouse", 1, 1);
    }

    // 2
    @Test
    void memberWhoAlreadyHoldsAProxyIsRefusedASecondOne() {
        clubWithOpenRound("alice", "bob", "carol");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.assertNamingProxyRefused("carol", "bob", "new-clubhouse");
    }

    // 3
    @Test
    void absentMembersOwnVoteCountsWhenCastAfterTheProxyVote() {
        clubWithOpenRound("alice", "bob");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.proxyVotes("bob", "alice", "new-clubhouse", "no");
        voting.memberVotes("alice", "new-clubhouse", "yes");
        voting.roundClosesFor("new-clubhouse");
        voting.assertResult("new-clubhouse", 1, 0);
    }

    // 3
    @Test
    void proxyVoteIsDroppedWhenAbsentMemberAlreadyVoted() {
        clubWithOpenRound("alice", "bob");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.memberVotes("alice", "new-clubhouse", "yes");
        voting.proxyVotes("bob", "alice", "new-clubhouse", "no");
        voting.roundClosesFor("new-clubhouse");
        voting.assertResult("new-clubhouse", 1, 0);
    }

    // 4
    @Test
    void tallyCountsProxyVotesAndReportsHowManyCameByProxy() {
        clubWithOpenRound("alice", "bob", "carol", "dave");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.memberNamesProxy("carol", "dave", "new-clubhouse");
        voting.memberVotes("bob", "new-clubhouse", "yes");
        voting.proxyVotes("bob", "alice", "new-clubhouse", "yes");
        voting.memberVotes("dave", "new-clubhouse", "no");
        voting.proxyVotes("dave", "carol", "new-clubhouse", "no");
        voting.roundClosesFor("new-clubhouse");
        voting.assertResult("new-clubhouse", 2, 2);
        voting.assertProxyVotes("new-clubhouse", 2);
    }

    // 5
    @Test
    void namingAProxyOnAClosedRoundIsRefused() {
        clubWithOpenRound("alice", "bob");
        voting.roundClosesFor("new-clubhouse");
        voting.assertNamingProxyRefused("alice", "bob", "new-clubhouse");
    }

    // 6
    @Test
    void proxyCoversOnlyTheRoundItWasNamedFor() {
        clubWithOpenRound("alice", "bob");
        voting.roundOpensFor("garden-fence");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.assertProxyVoteRefused("bob", "alice", "garden-fence", "yes");
    }

    // 7
    @Test
    void namingYourselfAsProxyIsRefused() {
        clubWithOpenRound("alice");
        voting.assertNamingProxyRefused("alice", "alice", "new-clubhouse");
    }

    // 8
    @Test
    void nonMemberCannotHoldAProxy() {
        clubWithOpenRound("alice");
        voting.assertNamingProxyRefused("alice", "mallory", "new-clubhouse");
    }

    // 8
    @Test
    void nonMemberCannotAppointAProxy() {
        clubWithOpenRound("bob");
        voting.assertNamingProxyRefused("mallory", "bob", "new-clubhouse");
    }

    // 9
    @Test
    void proxyHolderCannotAppointTheirOwnProxyInTheSameRound() {
        clubWithOpenRound("alice", "bob", "carol");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.assertNamingProxyRefused("bob", "carol", "new-clubhouse");
    }

    // 10
    @Test
    void newAppointmentReplacesTheEarlierOne() {
        clubWithOpenRound("alice", "bob", "carol");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.memberNamesProxy("alice", "carol", "new-clubhouse");
        voting.assertProxyVoteRefused("bob", "alice", "new-clubhouse", "yes");
        voting.proxyVotes("carol", "alice", "new-clubhouse", "yes");
        voting.roundClosesFor("new-clubhouse");
        voting.assertResult("new-clubhouse", 1, 0);
    }

    // 10
    @Test
    void replacementIsRefusedWhenTheNewHolderAlreadyHoldsAProxy() {
        clubWithOpenRound("alice", "bob", "carol", "dave");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.memberNamesProxy("dave", "carol", "new-clubhouse");
        voting.assertNamingProxyRefused("alice", "carol", "new-clubhouse");
        voting.proxyVotes("bob", "alice", "new-clubhouse", "yes");
        voting.roundClosesFor("new-clubhouse");
        voting.assertResult("new-clubhouse", 1, 0);
    }

    // 11
    @Test
    void holderCannotCastAProxyVoteForSomeoneWhoDidNotNameThem() {
        clubWithOpenRound("alice", "bob", "carol");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.assertProxyVoteRefused("bob", "carol", "new-clubhouse", "yes");
    }

    // 12
    @Test
    void droppedProxyVoteIsNotCountedAsAProxyVote() {
        clubWithOpenRound("alice", "bob");
        voting.memberNamesProxy("alice", "bob", "new-clubhouse");
        voting.memberVotes("alice", "new-clubhouse", "yes");
        voting.proxyVotes("bob", "alice", "new-clubhouse", "no");
        voting.roundClosesFor("new-clubhouse");
        voting.assertProxyVotes("new-clubhouse", 0);
    }
}
