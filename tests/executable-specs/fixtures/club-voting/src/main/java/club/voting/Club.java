package club.voting;

import java.util.*;

public class Club {
    private final Set<String> members = new HashSet<>();
    private final Map<String, Round> rounds = new HashMap<>();

    public void join(String member) { members.add(member); }

    public boolean isMember(String member) { return members.contains(member); }

    public Round openRound(String proposal) {
        Round round = new Round(proposal);
        rounds.put(proposal, round);
        return round;
    }

    public Round round(String proposal) { return rounds.get(proposal); }
}
