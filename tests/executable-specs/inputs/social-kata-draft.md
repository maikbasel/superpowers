# Social Networking Kata — Design Draft

Date: 2026-10-23
Brief: `KATA.md` (Codurance Social Networking Kata)

## Intent and why

Build the kata as a practice exercise in **strict outside-in TDD**. The
finished app matters less than the way it's built: design is driven from a
failing end-to-end acceptance test inward, one collaborator at a time, and
the commit history shows each red → green → refactor step.

## Goals

- A console app that satisfies every scenario in `KATA.md`: posting,
  reading, following, wall.
- Acceptance tests, one per slice, that drive the whole app through its console
  boundary. Each is written first and stays red until the innermost
  collaborator is real.
- Unit tests for each class, with collaborators replaced by hand-written
  test doubles.
- One commit per TDD step, so the history can be reviewed.

## Non-goals

- Persistence. Everything lives in memory for the life of the process.
- User accounts, authentication, validation of names beyond parsing.
- Any UI other than stdin/stdout.

## Anti-goals

- Tests that depend on the real system clock or real stdin/stdout. That
  makes them flaky or untestable.
- Mocking libraries such as Mockito. The user chose hand-written fakes.
- Building inside-out: a class may only appear when a test one level up
  needs it.

## Constraints

- Java 21, Maven 3.9.9 (see `.tool-versions`), JUnit 5.10.2 (already in
  `pom.xml`).
- No new test dependencies unless a tool clearly fits. Testcontainers was
  considered and does not fit: there is no infrastructure to stand in for.

## Approaches

1. **Mock-driven outside-in with Mockito.** The usual London-school way.
   Rejected because the user prefers fakes over a mocking library.
2. **Mock-driven outside-in with hand-written doubles (chosen).** The same
   design flow: each test names the collaborators it needs as interfaces,
   implemented in tests by small fakes or spies. Costs a bit more test
   code, but there's no library, and the doubles read as plain Java.
3. **Acceptance test plus tests with real objects (Chicago style).** Sturdier
   tests, but the design comes out of refactoring rather than being driven
   from the outside. Rejected because it isn't strict outside-in.

## Decided how

- Outside-in, driven by one acceptance test at the console boundary
  (user's decision).
- Test doubles are hand-written fakes and spies, not Mockito (user's
  decision).
- Time comes through an injected clock abstraction. Console I/O comes
  through an injected console abstraction (my call, needed for
  deterministic tests).
- Commit after every TDD step (user deferred to the workflow). Red commits
  that fail the build are allowed. Their messages start with `RED:`. Commits
  stay local (user's decision).
- Several acceptance tests, one per vertical slice (user's decision):
  first post and read, then follow and wall. Each slice starts with its own
  failing console-level test and adds to the classes that already exist.
  Edge cases (time units, parsing, duplicates) are covered by unit tests,
  not through the console.

## Behaviours

Each line becomes an acceptance test, or a case within one. "T" is the
moment the command is entered. Times are shown relative to T.

### Posting and reading
1. `Alice -> I love the weather today`, followed 5 minutes later by `Alice`,
   prints `I love the weather today (5 minutes ago)`.
2. Bob posts `Damn! We lost!` and then `Good game though.` 1 minute later.
   Reading `Bob` 1 minute after that prints `Good game though. (1 minute ago)`
   and then `Damn! We lost! (2 minutes ago)`. Newest first.
3. A post command prints nothing.
4. Reading a user who has never posted prints nothing (my call).
5. Messages may contain any text, including `->`, `follows` and `wall`.
   Only the first ` -> ` separates the name from the message (my call).
5a. Reading a user shows only their own posts, never posts of users they
    follow.
5b. Relative time is computed when the read or wall command is entered:
    reading the same post again 2 minutes later shows a time 2 minutes
    larger.
5c. User names are case-sensitive: `alice` and `Alice` are different users
    (my call).

### Following and wall
6. Charlie posts, follows Alice, and the wall shows Charlie's and Alice's
   posts merged newest first, as `<name> - <message> (<time>)`. This matches
   the brief's example.
7. After also following Bob, the wall shows all three users' posts merged
   newest first. This matches the brief's example.
8. A follow command prints nothing.
9. Following the same user twice doesn't duplicate their posts on the wall
   (my call).
10. Following yourself doesn't duplicate your posts on the wall (my call).
11. Following a user who hasn't posted yet is allowed. Their posts appear
    on the wall once they post (my call).
12. The wall of a user with no posts and no follows prints nothing. The
    wall of a user with no posts of their own shows the posts of the users
    they follow (my call).
13. Posts made at the same instant keep the order they were entered in,
    newest-entered first. This holds on timelines and when the wall merges
    different users' posts (my call).
13a. A wall includes a followed user's posts made before the follow.
13b. Following isn't transitive. If Charlie follows Alice and Alice follows
     Bob, Bob's posts don't appear on Charlie's wall.

### Relative time (all my call; the brief only shows examples)
Every unit is rounded down: 59s is `59 seconds ago`, 90 minutes is
`1 hour ago`, and 36 hours is `1 day ago`.
14. Under 1 minute: `N seconds ago`, with `1 second ago` singular and
    `0 seconds ago` for the same instant.
15. Under 1 hour: `N minutes ago` (whole minutes, rounded down),
    `1 minute ago` singular.
16. Under 1 day: `N hours ago`, `1 hour ago` singular.
17. Otherwise: `N days ago`, `1 day ago` singular.

### Console
18. Before reading each command, the app prints the prompt `> ` with no
    newline. This includes one final prompt before end of input is detected
    (my call; it matches the brief's transcript).
18a. Output lines end with `\n`. The blank line in the brief's transcript is
     only layout and is not printed (my call).
18b. The acceptance tests assert the full output stream, prompts included.
19. Blank input lines are ignored (my call).
20. When input ends (EOF), the app's run method returns normally and
    `main` exits with code 0. There is no exit command (my call).
21. Parsing (my call). The line is trimmed. A user name is one word with no
    whitespace. Commands, checked in this order:
    - `<name> -> <message>`, where the message isn't empty, is a post.
    - `<name> follows <name>` is a follow.
    - `<name> wall` is a wall.
    - `<name>` alone is a read.
    Anything else is silently ignored, so the only output is the next
    prompt. Examples: `Alice follows Bob -> hi` (the name has spaces),
    `Alice -> ` (empty message), `Alice follows` (no target).

## Left to the builder

- Class and package names, and how far to split the inner collaborators
  (parser, command objects, repository, formatter).
- How to make the app runnable (`exec-maven-plugin`, a `main` class run
  via `java -cp`, etc.).
- Whether to pin the Surefire version explicitly.
