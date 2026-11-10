<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0002. Concurrency model

- **Status:** Proposed
- **Date:** 2026-10-22
- **Deciders:** mb6ockatf
- **Issue:** #3
- **Blocks:** #5, #6, #7, #119

## Context

oranged and orange-agent are both network programs that hold many connections,
timers and protocol state machines at once. The server module interface (#5) and
the storage interface (#6) depend on how work is scheduled, so this has to be
settled before they are written.

Forces and constraints:

- Standalone asio is the networking library; it supports both completion
  callbacks and C++20 coroutines (`asio::awaitable`).
- Some work blocks: SQLite calls and password hashing for SCRAM.
- Shared mutable state (sessions, rosters, routing tables) is simple on one
  thread and needs locking on several.
- CI already runs ASan and UBSan; TSan is only useful once there are threads
  (#70).
- Error handling ([0001](0001-error-handling.md)) has to work across whatever
  boundaries this model creates.

Questions this ADR must answer:

- [ ] #23 One `asio::io_context` on one thread for oranged and for orange-agent,
  at least until profiling says otherwise?
- [ ] #24 C++20/23 coroutines (`asio::awaitable`) for protocol state machines,
  or callbacks? Rules for lifetimes across `co_await`.
- [ ] #25 Blocking work (SQLite, SCRAM hashing): run on a thread pool and post
  results back? Which pool, how big?
- [ ] #26 Timers and timeouts: who owns them, how are they cancelled when a
  connection closes?
- [ ] #27 What would have to change to go multi-threaded later, so today's code
  does not make it impossible?

## Options considered

1. **One `io_context` on one thread, coroutines, a small thread pool for
   blocking work.**
   - Pros: ...
   - Cons: ...
2. **One `io_context` on one thread, completion callbacks.**
   - Pros: ...
   - Cons: ...
3. **One `io_context` run by several threads, with strands per connection.**
   - Pros: ...
   - Cons: ...
4. **Do nothing (decide per component).**
   - Cons: ...

## Decision

We will ...

Why this option beats the others, tied back to the forces in Context.

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Follow-ups:**
  - The server module interface spec (#5) relies on this model.
  - The storage interface spec (#6) says how blocking calls are dispatched
    (#46).
- **Revisit when:** ...
