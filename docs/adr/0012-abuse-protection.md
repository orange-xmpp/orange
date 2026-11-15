<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0012. Abuse protection and rate limits

- **Status:** Proposed
- **Date:** 2026-10-28
- **Deciders:** mb6ockatf
- **Issue:** #123
- **Blocks:** #79, #82

## Context

oranged accepts connections from the network, so it must survive clients that
are broken or hostile. Even without federation, one client can flood the server
with stanzas, open many connections, guess passwords or never read its socket.
The listener (#79) and authentication (#82) need these limits before they are
written; federation (v0.3) extends this ADR to other servers.

Forces and constraints:

- Performance is the main goal ([0002](0002-concurrency.md)): a check runs on
  every stanza, so it must be cheap and must not need locks across shards.
- A connection lives on one shard, but an account's sessions and an IP's
  connections may be spread over several shards.
- [0002](0002-concurrency.md) already decided two limits: a byte limit on each
  connection's outgoing queue, closed with `policy-violation`, and idle
  deadlines that are short before authentication and long after it.
- [0001](0001-error-handling.md) limits input size and logs errors caused by a
  remote peer at debug level, so a hostile client cannot flood the log.
- Limits are settings ([0003](0003-configuration.md)) and need defaults that are
  safe on a small server.
- A legitimate client must not notice the limits in normal use, such as sending
  a burst of presence and roster requests just after login.

Questions this ADR must answer:

- [ ] Rate limits: per connection, per account, per IP address? Counted in bytes
  or stanzas per second?
- [ ] What happens when a limit is exceeded: slow down reading, return a stanza
  error, or close the stream?
- [ ] Failed logins: how many before a delay or a block, for how long, and per
  account or per IP address?
- [ ] How many connections one IP address and one account may open.
- [ ] Registration: closed by default (admin command only, #93), invitations
  later?
- [ ] Which limits are settings ([0003](0003-configuration.md)), and their
  defaults.

## Options considered

1. **Token bucket per connection, in bytes, slowing down reads when empty.**
   - Pros: ...
   - Cons: ...
2. **Token buckets per connection, per account and per IP address.**
   - Pros: ...
   - Cons: ...
3. **Fixed limits that close the stream when exceeded.**
   - Pros: ...
   - Cons: ...
4. **Do nothing (leave it to a firewall or a proxy in front of oranged).**
   - Cons: ...

## Decision

We will ...

Why this option beats the others, tied back to the forces in Context.

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Follow-ups:**
  - The listener (#79) and authentication (#82) implement these limits.
  - The limits and their defaults go into the configuration
    ([0003](0003-configuration.md)).
  - Federation (v0.3) extends this ADR to server-to-server connections.
- **Revisit when:** ...
