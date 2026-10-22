package club.voting;

import java.util.*;

public class Round {
    private final String proposal;
    private final Map<String, Boolean> votes = new HashMap<>();
    private boolean closed;

    Round(String proposal) { this.proposal = proposal; }

    public void vote(String member, boolean yes) { votes.put(member, yes); }

    public void close() { closed = true; }

    public boolean isClosed() { return closed; }

    public Tally tally() {
        long yes = votes.values().stream().filter(v -> v).count();
        return new Tally((int) yes, votes.size() - (int) yes);
    }

    public record Tally(int yes, int no) {}
}
