# 1. Membership is checked by the website, not the library

Date: 2026-03-02

## Status

Accepted

## Context

The club website is the only caller of this library. It already knows who is logged in and whether they are a member.

## Decision

`Round` accepts a vote from anyone. The website only shows the vote button to members.

## Consequences

The library stays small and has no notion of membership rules. Anyone calling the library directly can vote without being a member.

## Rejected options

- **Check membership in `Round`.** Duplicates what the website does, for a library with one caller.
