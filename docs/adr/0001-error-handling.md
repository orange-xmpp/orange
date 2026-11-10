<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0001. Error handling

- **Status:** Accepted
- **Date:** 2026-10-22
- **Deciders:** mb6ockatf
- **Issue:** #2
- **Blocks:** #4, #5, #6, #7

## Context

Four people will write liborange, oranged and the client at the same time.
Without one rule for reporting failures, each of them invents a style, and every
boundary between their code needs a translation layer. Decide once, before the
0.1 protocol code starts.

Forces and constraints:

- C++23 with GCC 14 / Clang 18 as the minimum; `std::expected` with monadic
  operations is available and checked by `ORANGE_CXX23`.
- liborange is a shared library (LGPL) with a public API in
  `lib/include/orange/`; what crosses that boundary is part of its ABI.
- XMPP defines its own error vocabulary: stream errors (RFC 6120 §4.9) and
  stanza errors (RFC 6120 §8.3).
- Most failures are expected: malformed or hostile input from the network,
  protocol violations, I/O errors.
- Standalone asio reports I/O errors as `std::error_code`.
- The concurrency model ([0002](0002-concurrency.md)) decides whether errors
  cross coroutine and thread boundaries.

Questions this ADR must answer:

- [x] #18 `std::expected<T, E>` for expected failures? What is `E`: one error
  enum per module, a shared `orange::error` type, `std::error_code`?
- [x] #19 Are exceptions allowed at all? Only for programming errors and
  out-of-memory? Never across the liborange API?
- [x] #20 How a protocol error becomes an XMPP stream error or stanza error, and
  who maps it.
- [x] #21 Logging: what gets logged where, and is there one logging interface?
- [x] #22 `assert` / contracts for invariants: on in release builds or not?

## Options considered

1. **`std::expected<T, E>` with one shared `orange::error` type.**
   - Pros: one vocabulary for the whole project; the type can carry any context
     we want (line numbers, the offending element).
   - Cons: one central file that every module edits; OS and asio errors must be
     wrapped before they fit.
2. **`std::expected<T, E>` with one error enum per module.**
   - Pros: each module owns its errors; easy to test.
   - Cons: the same errors are defined again in different modules; enums from
     different modules cannot be compared or passed through a common interface.
3. **`std::error_code` with a custom error category, without `std::expected`.**
   - Pros: classic UNIX errors; easy to understand; asio already uses it.
   - Cons: the result has to travel in an out parameter next to the error; an
     `error_code` holds only a number and a category, with no room for context.
4. **`std::expected<T, std::error_code>` with an error category per module.**
   - Pros: one return type everywhere; OS and asio errors pass through
     unchanged; each module still owns its enum; codes from different modules
     compare through `std::error_code`; monadic operations chain calls without
     nested checks.
   - Cons: boilerplate for every category; no context in the error itself.
5. **Exceptions for all failures.**
   - Pros: a clean happy path; constructors can fail.
   - Cons: hidden control flow; hostile input makes the server throw at the
     attacker's pace, which is slow; exceptions across the liborange shared
     library boundary bind its ABI to the compiler's runtime.
6. **Do nothing (each component chooses its own style).**
   - Cons: no unified style; hard to test; hard to document.

## Decision

We will return `std::expected<T, std::error_code>` from every function that can
fail in an expected way, with an error category per module (option 4). An
expected error never stops the system; it is returned to the caller. For
example:

```cpp
std::expected<orange::jid, std::error_code> parse_jid(std::string_view text);
```

OS errors pass through unchanged and keep their errno meaning. Protocol errors
use an error enum of their own module, such as `orange::xml_errc`,
`orange::jid_errc` or `orange::sasl_errc`, registered with
`std::is_error_code_enum`.

Crashes are not error codes, since nothing can handle them correctly:

- Out-of-memory (`std::bad_alloc`) is never caught locally. It propagates to
  `main`, which logs it, and the program exits.
- Programming errors are caught in two ways. Cheap internal checks use `assert`,
  which is compiled out of release builds (`./configure --disable-assert`).
  Invariants that protect memory safety, such as bounds on buffers, are checked
  explicitly and call `std::terminate` in every build.

Expected failures never throw. No exception other than `std::bad_alloc` crosses
the liborange API.

asio reports asynchronous I/O errors by throwing exceptions by default, so
always use `asio::as_tuple(asio::use_awaitable)`.

An error is logged once, by the function that detects it, because only that
function has the context (the input, the peer, the line). Callers that only pass
the `error_code` on do not log it again. Errors caused by a remote peer are
logged at debug level, so a hostile client cannot flood the log. All logging
goes through one interface, implemented in #94.

Incomplete input, such as a stanza split across several reads, is never an
error; malformed or oversized input is. Input size is limited, and the limits
are tested.

For each error category, one function turns an `error_code` into an RFC 6120
stream or stanza error condition; the stream layer calls it. Modules never build
XMPP error replies by hand.

This is the only option that gives four people one return type to agree on
without a central error type everyone edits. It keeps asio and OS errors as they
are, keeps exceptions away from hostile input and the liborange ABI, and maps
cleanly onto the XMPP error vocabulary in one place.

## Consequences

- **Positive:** one way to report failure across liborange, oranged and the
  client; OS and asio errors need no wrapping; XMPP error replies are built in
  one place; hostile input never triggers an exception.
- **Negative:** every module writes the category boilerplate (the enum, the
  category class, `make_error_code`, the `is_error_code_enum` specialization).
  An `error_code` carries no context, so the detecting function must log it.
  Every asio call needs `as_tuple`, and callers check results explicitly.
- **Follow-ups:**
  - A short code example of the chosen pattern, which the socket-path code in
    `client/core/` follows (or is changed to follow).
  - The logging interface, implemented in #94.
  - `AC_HEADER_ASSERT` in `configure.ac`, so `--disable-assert` works;
    `config.h` is included before `<cassert>`.
  - Input size limits, set in the configuration ([0003](0003-configuration.md)).
- **Revisit when:** several modules need context next to the `error_code` (line
  numbers, offending elements), or C++26 contracts are available with the
  minimum compiler.
