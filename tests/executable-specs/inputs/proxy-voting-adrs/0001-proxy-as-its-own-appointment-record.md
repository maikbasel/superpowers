# 1. Record a proxy as an appointment on the round, not as an attribute of a vote

Date: 2026-10-22
Status: Proposed

## Context

Members who travel miss rounds, so a member can name another member to cast their vote for one round. The club also wants to avoid a few people collecting everyone's vote, and wants to see appointments before anyone votes. The rules about who may hold a proxy are rules about appointments.

## Decision

A round keeps its own appointments (absent member to holder). The rules are checked when a proxy is named, and voting looks the appointments up.

## Consequences

Rules are checked where they are decided, and appointments are visible before voting. It is more code than the alternative. `Round` needs to know club membership, which `Club` must supply.

## Rejected options

- **Proxy as an optional "cast by" attribute on `Round.vote`.** Smallest change, but the rules would be checked at vote time and nobody could see appointments before voting.
