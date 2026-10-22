package club.voting.acceptance.drivers;

import club.voting.Club;

/** Protocol driver: reaches the system through its Java API. */
public class LibraryDriver {
    private final Club club = new Club();

    public void join(String member) { club.join(member); }
    public void openRound(String proposal) { club.openRound(proposal); }
    public void vote(String member, String proposal, boolean yes) { club.round(proposal).vote(member, yes); }
    public void closeRound(String proposal) { club.round(proposal).close(); }
    public int yesVotes(String proposal) { return club.round(proposal).tally().yes(); }
    public int noVotes(String proposal) { return club.round(proposal).tally().no(); }
}
