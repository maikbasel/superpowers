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
    public void assertResult(String proposal, int yes, int no) {
        assertEquals(yes, driver.yesVotes(proposal));
        assertEquals(no, driver.noVotes(proposal));
    }
}
