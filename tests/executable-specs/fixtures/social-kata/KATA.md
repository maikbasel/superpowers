# Social Networking Kata

A console-based social networking application, like a tiny Twitter,
satisfying these scenarios.

**Posting:** Alice can publish messages to a personal timeline.

```
> Alice -> I love the weather today
> Bob -> Damn! We lost!
> Bob -> Good game though.
```

**Reading:** Bob can view Alice's timeline.

```
> Alice
I love the weather today (5 minutes ago)
> Bob
Good game though. (1 minute ago)
Damn! We lost! (2 minutes ago)
```

**Following:** Charlie can subscribe to Alice's and Bob's timelines and
view an aggregated list of all subscriptions on his wall.

```
> Charlie -> I'm in New York today! Anyone want to have a coffee?
> Charlie follows Alice
> Charlie wall
Charlie - I'm in New York today! Anyone want to have a coffee? (15 seconds ago)
Alice - I love the weather today (5 minutes ago)

> Charlie follows Bob
> Charlie wall
Charlie - I'm in New York today! Anyone want to have a coffee? (15 seconds ago)
Bob - Good game though. (1 minute ago)
Bob - Damn! We lost! (2 minutes ago)
Alice - I love the weather today (5 minutes ago)
```

## Commands

- posting: `<user name> -> <message>`
- reading: `<user name>`
- following: `<user name> follows <another user>`
- wall: `<user name> wall`

## Details

- The application uses the console for input and output.
- Users submit commands to the application.
- Users are created as soon as they post their first message.
- There is no need for persistence.
- Message lists are newest first.

Source: the Codurance Social Networking Kata.
