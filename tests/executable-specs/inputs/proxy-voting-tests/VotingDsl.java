package club.voting.acceptance.dsl;

import club.voting.acceptance.drivers.LibraryDriver;
import static org.junit.jupiter.api.Assertions.*;

/** Domain language for acceptance tests. No knowledge of how the system is reached. */
public class VotingDsl {
    private final LibraryDriver driver = new LibraryDriver();

    public void memberJoins(String member) { driver.join(member); }
    public void roundOpensFor(String proposal) { driver.openRound(proposal); }
    public void memberVotes(String member, String proposal, String choice) { driver.vote(member, proposal, choice.equals("yes")); }
    public void roundClosesFor(String proposal) { driver.closeRound(proposal); }
    public void memberNamesProxy(String member, String holder, String proposal) { throw notImplemented("memberNamesProxy"); }
    public void proxyVotes(String holder, String forMember, String proposal, String choice) { throw notImplemented("proxyVotes"); }
    public void assertNamingProxyRefused(String member, String holder, String proposal) { throw notImplemented("assertNamingProxyRefused"); }
    public void assertProxyVoteRefused(String holder, String forMember, String proposal, String choice) { throw notImplemented("assertProxyVoteRefused"); }
    public void assertProxyVotes(String proposal, int count) { throw notImplemented("assertProxyVotes"); }
    private static UnsupportedOperationException notImplemented(String step) { return new UnsupportedOperationException("not implemented: " + step); }
    public void assertResult(String proposal, int yes, int no) {
        assertEquals(yes, driver.yesVotes(proposal));
        assertEquals(no, driver.noVotes(proposal));
    }
}
