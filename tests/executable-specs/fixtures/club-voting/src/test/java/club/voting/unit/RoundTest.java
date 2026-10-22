package club.voting.unit;

import club.voting.Club;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class RoundTest {
    @Test
    void laterVoteReplacesEarlierVote() {
        var round = new Club().openRound("p");
        round.vote("alice", true);
        round.vote("alice", false);
        assertEquals(0, round.tally().yes());
        assertEquals(1, round.tally().no());
    }
}
