# Club voting

A small library our club's website uses to run votes on proposals.
Members join the club, a round opens for a proposal, members vote yes/no, the round closes, and the result is tallied.

Tests: `mvn test`. Acceptance tests live in `src/test/java/club/voting/acceptance`
and use the domain DSL in `acceptance/dsl`; drivers in `acceptance/drivers` talk to the code.
