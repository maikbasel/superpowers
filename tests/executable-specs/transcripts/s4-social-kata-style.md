# Conversation so far

Taken from kata run 1, with an unrelated CodeGraph aside removed.

**Human partner:** Let's build the social networking kata in KATA.md

**Agent (you):** You want the Codurance social networking kata built in this Maven/Java 21 project. It's a console app where users post to their own timelines, read anyone's timeline, follow other users, and view a wall that merges their own posts with the posts of everyone they follow. Lists show newest first, with relative times like "5 minutes ago", and nothing is saved between runs.

What's in the repo now:
- **Code:** none yet. There's only `KATA.md`, a `pom.xml` with JUnit 5.10.2 and `.tool-versions`.
- **`pom.xml`:** it doesn't pin the Surefire test plugin. Older Maven defaults won't find JUnit 5 tests, so I'd pin it.
- **Clock:** the relative times mean the code needs a clock that tests can control. That choice affects most of the design.
- **Examples in the brief:** the times in `KATA.md` don't quite match each other ("15 seconds ago" sitting next to entries posted earlier). The exact wording rules, like "1 minute" vs "1 minutes" and when to switch to hours, aren't specified, so I'd decide them.

Correct me if I've got any of that wrong.

The big question: since this is a kata, is the point for you to practise a particular style (strict outside-in TDD from an acceptance test, small commits per step, pairing with me step by step), or do you mostly want a clean finished solution?

**Human partner:** strict outside-in TDD

**Agent (you):** So the plan is strict outside-in TDD. The first step is a failing acceptance test that drives the whole console app: commands go in, output comes out, and the clock is faked so the times are predictable. That test stays red while I work inward one class at a time, with each new class pinned down by its own test using stand-ins for the parts that don't exist yet. When the innermost pieces are real, the acceptance test turns green.

How do you want to be involved: should I stop at each red → green → refactor step so you can steer, or run the whole thing myself with one commit per step so you can review the history afterwards?

**Human partner:** whatever the plugin workflow says
