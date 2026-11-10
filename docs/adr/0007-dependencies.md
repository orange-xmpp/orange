<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0007. Build on asio, expat, OpenSSL, SQLite and Catch2

- **Status:** Proposed
- **Date:** 2026-10-18
- **Deciders:** mb6ockatf
- **Issue:** #116

## Context

Every dependency is something distributions must package, users must install,
and we must keep up with. Too few, and we write and fuzz our own TLS or XML
parser; too many, and Orange is hard to build.

Questions this ADR must answer:

- [ ] Why standalone asio, expat, OpenSSL 3, SQLite and Catch2 v3, and what each
  one was weighed against.
- [ ] Bundled or system packages; minimum versions checked in `configure.ac`.
- [ ] The rule for adding a new dependency: who approves it, what it must
  justify (license, Debian packaging, maintenance).

## Options considered

1. **Networking:** standalone asio, Boost.Asio, libuv, or our own epoll loop.
   - Pros and cons: ...
2. **XML:** expat, libxml2, or our own parser.
   - Pros and cons: ...
3. **TLS:** OpenSSL 3 or GnuTLS.
   - Pros and cons: ...
4. **Storage:** SQLite, or plain files.
   - Pros and cons: ...
5. **Tests:** Catch2 v3 or GoogleTest.
   - Pros and cons: ...

## Decision

We depend on standalone asio, expat, OpenSSL 3, SQLite and Catch2 v3.

Why these beat the others: ...

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Follow-ups:**
  - #17 is closed with a link to this ADR.
  - libsecret, for the client only, is added by
    [0008](0008-credential-storage.md); list it here once 0008 is accepted.
- **Revisit when:** ...
