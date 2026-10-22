---
name: writing-adrs
description: Use when a design draft is written and its decisions need a lasting record, or when a new decision changes or reverses an earlier one
---

# Writing ADRs

The design draft is temporary. Its decisions, and why they were made, live
on in ADRs. Behaviours go to acceptance tests, not here.

**Announce at start:** "I'm using the writing-adrs skill to record the
decisions."

## What gets an ADR

One ADR per real decision: there were options, one was chosen for a
reason, and the choice constrains later work. The approach your human
partner picked is always one. So is a rule chosen over a clear
alternative for a stated reason ("one proxy per holder, so nobody
collects votes").

Not an ADR: a behaviour with no choice behind it, a detail the draft
leaves to the builder, a name or signature.

Your own calls that are real decisions get an ADR too. Their status is
Proposed like every other new ADR, so your human partner confirms them
at spec approval along with the rest.

## The record

In a software repo: `docs/decisions/NNNN-<the-decision-in-a-few-words>.md`,
numbered after the highest existing one. If the project already keeps
ADRs somewhere else, use that place. Your human partner's preferences
override both.

Every ADR has these parts, in this order, whatever format the project
uses:

```markdown
# N. <The decision, stated as a decision>

Date: YYYY-MM-DD
Status: Proposed
Supersedes: <ADR number, only when it reverses one>

## Context

What forced the choice, in the domain's words.

## Decision

What was chosen, in a few sentences.

## Consequences

What gets easier, what gets harder, what is now ruled out.

## Rejected options

- **<Option>.** Why not.
```

Rejected options is never empty. A choice with no alternative wasn't a
decision; drop the ADR.

## Status

`Proposed` → `Accepted` → `Superseded by M`.

You write `Proposed`, always. `Accepted` is set when your human partner
approves the spec, the ADRs and acceptance tests together. Picking an
approach in the conversation is not approving its ADR.

## When a decision reverses an earlier one

Read the accepted ADRs before you write. When a new decision contradicts
one, the new ADR names it under `Supersedes:` and says how in Context.
Leave the old ADR as it is. It becomes `Superseded by M` only when your
human partner approves the spec. Tell them which ADR it reverses.

## Don't commit

Leave the ADRs uncommitted. In this workflow a commit is the approval:
approved ADRs and acceptance tests are committed together, and committed
ones are read-only.

## Hand off

Tell your human partner in a few lines: which ADRs you wrote, which of
them are your own calls, and which earlier ADR any of them reverses. Say
they'll approve the ADRs together with the acceptance tests, next. Don't
ask for approval now.

Then invoke superpowers:writing-acceptance-tests and no other skill.

## Red Flags

| Thought | Reality |
|---------|---------|
| "They picked it, so it's Accepted" | Picking isn't approving the record. Proposed. |
| "It's my unconfirmed call, so no ADR" | Write it as Proposed. Approval is where it gets confirmed. |
| "The old ADR is clearly outdated, I'll mark it superseded" | Accepted ADRs change only on approval. Name it under Supersedes. |
| "Commit it so it's saved" | A commit is the approval. Leave it uncommitted. |
| "This rule has no real alternative, but it's important" | Then it's a behaviour. It goes to a test. |
| "Decisions are recorded, next is the plan" | Next is writing-acceptance-tests. The plan comes after approval. |
