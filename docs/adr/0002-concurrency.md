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

- Performance is the project's main goal: the README promises a blazingly fast
  server. oranged must give maximum throughput and minimal latency, also under
  heavy load.
- orange-agent serves one user and holds a handful of connections.
- Standalone asio (1.30 on Debian 13) is the networking library; it supports
  both completion callbacks and C++20 coroutines (`asio::awaitable`).
- Some work blocks: SQLite calls and password hashing for SCRAM.
- Shared mutable state (sessions, rosters, routing tables) is simple on one
  thread and needs locking on several.
- CI already runs ASan and UBSan; TSan is only useful once there are threads
  (#70).
- The team has little experience with asynchronous and multi-threaded code,
  especially in C++.
- Error handling ([0001](0001-error-handling.md)) has to work across whatever
  boundaries this model creates.

Questions this ADR must answer:

- [x] #23 One `asio::io_context` on one thread for oranged and for orange-agent,
  at least until profiling says otherwise?
- [x] #24 C++20/23 coroutines (`asio::awaitable`) for protocol state machines,
  or callbacks? Rules for lifetimes across `co_await`.
- [x] #25 Blocking work (SQLite, SCRAM hashing): run on a thread pool and post
  results back? Which pool, how big?
- [x] #26 Timers and timeouts: who owns them, how are they cancelled when a
  connection closes?
- [x] #27 What would have to change to go multi-threaded later, so today's code
  does not make it impossible?

## Options considered

1. **One `io_context` on one thread, coroutines, a small thread pool for
   blocking work.**
   - Pros: all sessions, rosters and routing tables are touched by one thread
     only, so no locks are needed and there are no data races.
   - Cons: uses one CPU core, so total capacity is limited to what one core can
     handle; once that core is busy, messages queue and latency grows. One slow
     or blocking handler delays every user.
2. **One `io_context` on one thread, completion callbacks.**
   - Pros: no coroutine machinery; every step is an ordinary function you can
     read on its own.
   - Cons: a multi-step protocol gets chopped into many small callback
     functions. XMPP login is: open stream, STARTTLS, SASL authentication,
     resource bind. Keeping the connection object alive until the last callback
     runs is manual (`shared_from_this`). Error checks are repeated in every
     callback. Same one-core limit as option 1.
3. **One `io_context` run by several threads, with strands per connection.**
   - Pros: all CPU cores are used.
   - Cons: every shared structure needs a mutex or a strand. Bugs where two
     handlers change the same data at the same time are hard to catch and hard
     to reproduce. Threads compete for locks and pass the same data between CPU
     caches, which costs throughput and latency. CI needs TSan (#70).
4. **One `io_context` per thread, one thread per CPU core, each thread owning
   its own connections (sharding).**
   - Pros: all CPU cores are used, with no locks inside a shard. Shards talk
     only by sending messages to each other (`asio::post` onto the other shard's
     executor). Load spreads over all cores, so queues stay short and latency
     stays low under heavy load.
   - Cons: more complex than option 1. When user A on shard 1 messages user B on
     shard 2, routing becomes a message hop instead of a function call.
     Something must decide which shard owns which user. One user's sessions
     (phone, laptop) may land on different shards. Load can be uneven between
     shards. CI needs TSan (#70).
5. **Do nothing (decide per component).**
   - Cons: each component invents its own threading rules; races appear where
     components with different models meet.

## Decision

We will shard oranged (option 4) and run orange-agent on one thread (option 1).
Both use coroutines and a thread pool for blocking work.

Performance is the main goal, and option 4 is the only option that uses every
core without locks; it keeps latency low when one core would already be
saturated. Option 3 also uses every core, but locks and shared data make it both
slower and harder to get right. orange-agent holds a few connections for one
user, so sharding would add complexity and gain nothing there.

The team is new to asynchronous code (see Context), so the rules below keep the
model simple to follow, and oranged can run with a single shard while code is
written and debugged.

### Shards in oranged

- The number of shards is a setting ([0003](0003-configuration.md)). The default
  is the number of CPU cores. With one shard, oranged runs exactly like option
  1, which is how new code is first tested and debugged.
- Each shard is one thread running its own `asio::io_context`, created with
  concurrency hint 1 (only one thread ever calls `run()` on it). No other thread
  calls `run()` on a shard's `io_context`.
- Each shard has its own listening socket on the same port (`SO_REUSEPORT`); the
  kernel spreads new connections over the shards. A connection stays on the
  shard that accepted it for its whole life.
- Shards share nothing. Every piece of shared state has exactly one owner shard,
  and other shards ask the owner by posting a message to it:
  - Per-user state (the list of a user's sessions, the roster, presence) is
    owned by the user's home shard: a hash of the bare JID modulo the number of
    shards. Finding the owner needs no table, only that function. The JID is
    hashed only after PRECIS normalization ([0011](0011-jid-precis.md)), so
    `User@Example` and `user@example` share a home shard. The hash is keyed
    (SipHash with a key chosen at startup), so nobody can register accounts that
    all land on one shard.
  - Other shared state (multi-user chat rooms, server-to-server links) follows
    the same rule, hashed by its own JID or domain.
- A message posted to another shard carries values (copied or moved), never
  pointers or references to objects of the sending shard.
- All cross-shard messaging goes through one routing component, reviewed with
  extra care. Modules never post to other shards directly.
- Stanzas between two entities arrive in the order they were sent (RFC 6120
  §10.1). The design keeps that order: one sender's stanzas always take the same
  path, and every `post` queue is first in, first out. Routing never adds a
  shortcut that lets a later stanza overtake an earlier one, and a test with
  several shards checks the order.
- Modules follow the same rule: a module keeps no state shared between shards.
  Its state lives either in one instance per shard or on the home shard of the
  entity it belongs to; the module interface spec (#5) says which.

### Coroutines (#24)

Protocol state machines are coroutines returning `asio::awaitable`, not
callbacks. Every asio call uses `asio::as_tuple(asio::use_awaitable)`
([0001](0001-error-handling.md)). Each connection has exactly one writer
coroutine. Everything else appends to the connection's outgoing queue and wakes
the writer.

Lifetime rules across `co_await`:

1. A coroutine takes its parameters by value or by `std::shared_ptr`, never by
   reference, `std::string_view` or `std::span`: the caller's data may be gone
   when the coroutine resumes.
2. A lambda that is a coroutine captures nothing. Write a function with value
   parameters instead.
3. No pointer, reference or iterator into shared data (the session list, a
   roster) is kept across a `co_await`. Other coroutines on the same shard run
   while this one waits and may change or delete that data, so look it up again
   after resuming.
4. A connection's coroutines own the connection object (by value or
   `std::shared_ptr`), so it lives until the last of them returns.
5. Each connection has exactly one writer coroutine. Everything else appends to
   the connection's outgoing queue and wakes the writer. Two `async_write` calls
   on one socket at the same time would mix their bytes and break the XML
   stream.

The outgoing queue has a byte limit, a setting ([0003](0003-configuration.md)).
A peer that does not read its socket makes the queue grow; when it passes the
limit, the connection is closed with the `policy-violation` stream error. This
keeps one slow or hostile client from making the server buffer without bound
(see #123).

### Blocking work (#25)

- oranged has one `asio::thread_pool` for blocking work, shared by all shards.
  Its size is a setting ([0003](0003-configuration.md)); the default is two
  threads.
- Each pool thread opens its own SQLite connection; a connection is never used
  by two threads. `asio::thread_pool` gives no hook to set up its threads, so
  the connection is a `thread_local`, opened the first time its thread needs it.
- The database runs in WAL mode with a `busy_timeout`, so two pool threads
  writing at once wait for each other instead of failing with `SQLITE_BUSY`.
- Coroutines run blocking work through one helper, `run_blocking`, which runs a
  function on the pool and resumes the coroutine on its own shard. Nothing else
  posts to the pool.
- Blocking work returns `std::expected` like every other fallible function
  ([0001](0001-error-handling.md)).
- SCRAM key derivation (PBKDF2, when a password is set or changed) runs on the
  pool. Login only verifies HMACs against the stored keys, which is cheap and
  stays on the shard.
- orange-agent follows the same rules with its own pool of one thread, which
  also runs blocking libsecret calls ([0008](0008-credential-storage.md)).

### Timers and timeouts (#26)

- A timer belongs to the connection it serves and is created on that
  connection's shard. Nothing outside the connection holds it.
- Each connection has one deadline timer. A watchdog coroutine waits on it; when
  it expires, the watchdog closes the socket. Every successful read moves the
  deadline forward; a whitespace keepalive counts as a read.
- The deadline depends on the phase of the connection, and both values are
  settings ([0003](0003-configuration.md)):
  - Before authentication it is short (seconds), so a client that opens a
    connection and sends nothing, or sends very slowly, cannot hold it.
  - After authentication it is long, because a phone may stay silent for hours.
    Before closing, the server sends an XEP-0199 ping and closes only if no
    answer arrives.
- Closing a connection cancels its timers and closes its socket. Its pending
  operations then complete with `asio::error::operation_aborted`, and its
  coroutines return.
- Server-wide periodic jobs (cleanup, statistics) run once per shard, each on
  its own shard's timer.
- asio 1.30 has no `cancel_after`, and experimental APIs (`awaitable_operators`)
  are not used.

### Changing the model later (#27)

- oranged: more cores need no code change, only a different shard count.
- orange-agent: it is written by the same rules (no global mutable state, state
  owned by one object passed explicitly, coroutines, communication by `post`),
  so it can be sharded later without a rewrite.
- Option 3 stays out: code may never assume that two threads run the same
  `io_context`.

## Consequences

- **Positive:** oranged uses every core without locks, and latency stays low as
  load grows. With one shard it behaves like a single-threaded server, which
  keeps debugging simple. One rule ("one owner, ask by message") replaces
  locking everywhere. orange-agent stays as simple as possible.
- **Negative:** cross-shard messages add a hop, and some deliveries need two
  (sender's shard, recipient's home shard, recipient's session shard). One
  user's sessions may sit on different shards. `SO_REUSEPORT` ties oranged to
  Linux, which matches the GNU/Linux target. Developers must learn the coroutine
  lifetime rules, and reviewers must check them. oranged and orange-agent follow
  different models.
- **Follow-ups:**
  - The server module interface spec (#5) relies on this model.
  - The storage interface spec (#6) says how blocking calls are dispatched
    (#46), and covers the per-thread SQLite connections and WAL mode.
  - The module interface spec (#5) says whether a module is created once per
    shard or keeps its state on home shards.
  - The logging interface (#94) is called from every shard and pool thread, so
    it must be safe to call from any thread.
  - A routing spec: the home-shard hash and the cross-shard message types.
  - The `shards` and blocking-pool settings in the configuration
    ([0003](0003-configuration.md)).
  - A TSan build in CI for oranged (#70), run with several shards.
  - Abuse protection (#123) builds on the outgoing queue limits and idle
    deadlines.
  - A load target (users online, messages per second) and a latency budget (for
    example, p99 server-side delivery time), with a benchmark that measures
    them.
- **Revisit when:** the benchmark shows that cross-shard hops dominate delivery
  latency (then consider moving a connection to its user's home shard after
  resource bind), shards are badly unbalanced under real load, or orange-agent
  needs more than one core.
