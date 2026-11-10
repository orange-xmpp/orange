<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0007. Build on asio, expat, OpenSSL, SQLite and Catch2

- **Status:** Accepted
- **Date:** 2026-11-10
- **Deciders:** d1mark2
- **Issue:** #17

## Context

Every dependency is something distributions must package, users must install,
and we must keep up with. Too few, and we write and fuzz our own TLS or XML
parser; too many, and Orange is hard to build.

oranged and orange-agent need an event loop with sockets and timers, an
incremental parser for XML that arrives from untrusted peers, TLS, durable
storage, and a unit-test framework. TLS and XML parsing are the two places where
a home-made implementation is most dangerous.

Forces and constraints:

- Performance is the main goal; the networking layer must not cost throughput
  or latency ([0002](0002-concurrency.md)).
- The concurrency model uses C++20 coroutines (`asio::awaitable`) and a thread
  pool for blocking SQLite and SCRAM calls ([0002](0002-concurrency.md)).
- The target is Debian 13 (asio 1.30) and other GNU/Linux distributions;
  distributions must be able to build Orange from their own packages and ship
  security fixes for our dependencies without us.
- oranged is built with Autotools ([0004](0004-monorepo-autotools.md)), so
  every dependency needs a check in `configure.ac`.
- XML and TLS parse data from the network, so their security history matters.
- The team is small. Every dependency is more to learn, track and update.
- CI already runs ASan and UBSan, and every library must work under them.

Questions this ADR must answer:

- [x] Why standalone asio, expat, OpenSSL 3, SQLite and Catch2 v3, and what each
  one was weighed against.
- [x] Bundled or system packages; minimum versions checked in `configure.ac`.
- [x] The rule for adding a new dependency: who approves it, what it must
  justify (license, Debian packaging, maintenance).

## Options considered

1. **Networking:** standalone asio, Boost.Asio, libuv, or our own epoll loop.
   - Standalone asio: header-only, supports coroutines and timers, and has TLS
     support (`asio::ssl`). Cons: long compile times, and its API changes
     between versions.
   - Boost.Asio: the same API. Cons: needs Boost for one component.
   - libuv: mature. Cons: a C API with manual lifetimes, no coroutines, and no
     TLS, so we would still glue OpenSSL in ourselves.
   - Own epoll loop: no dependency. Cons: we would write and maintain timers,
     cancellation and portability ourselves, none of which is our product.
2. **XML:** expat, libxml2, or our own parser.
   - expat: a small push parser, so it handles XML that arrives in arbitrary
     chunks, which is what a stream from a socket does. It has no DTD loading,
     XPath or schemas. Cons: no DOM or validation, so we write a thin layer.
   - libxml2: has a push parser too. Cons: a much larger attack surface and
     CVE history, mostly in features we do not use (DTD loading, XPath,
     schemas).
   - Own parser: exactly the subset we need. Cons: a parser for untrusted input
     that we would have to fuzz and harden for as long as the project lives.
3. **TLS:** OpenSSL 3 or GnuTLS.
   - OpenSSL 3: `asio::ssl` is built on it, it is the most widely deployed TLS
     library, and 3.0 is an LTS release. Cons: a large API that is easy to
     misuse; license is Apache-2.0.
   - GnuTLS: LGPL, clean API. Cons: asio has no support for it, so we would
     write and maintain our own adapter; and two TLS libraries in one
     distribution's closure is a cost for packagers.
4. **Storage:** SQLite, or plain files.
   - SQLite: transactions and crash safety with no server process, and a
     public-domain license. Cons: one writer at a time, and a blocking API
     (see [0002](0002-concurrency.md)).
   - Plain files: no dependency. Cons: we would write atomic updates, locking,
     indexes and crash recovery ourselves.
5. **Tests:** Catch2 v3 or GoogleTest.
   - Catch2 v3: expressive assertions, sections for shared setup, generators,
     a compiled library, BSL-1.0 license. Cons: no mocking.
   - GoogleTest: widely used, includes gmock. Cons: more boilerplate, and gmock
     is the only thing we would gain, which we do not plan to use (tests use
     fakes).

## Decision

We depend on standalone asio, expat, OpenSSL 3, SQLite and Catch2 v3.

Why these beat the others: each is the smallest mature, widely packaged option
that does the job without a larger dependency closure. Standalone asio gives
the async model and coroutines without Boost. expat is a push parser with the
smallest attack surface for XML from the network. OpenSSL 3 is the TLS library
that asio supports and that Debian patches. SQLite replaces a storage engine we
would otherwise write. Catch2 v3 gives a good test workflow without a mocking
framework we do not want. We never write our own TLS, XML parser or storage
engine.

### System packages, not bundled

- All dependencies are system packages. We do not copy them into the source
  tree, and the build downloads nothing.
- This is so distributions can fix security problems in OpenSSL, expat and
  SQLite without waiting for us, and so builds work offline, as Debian
  requires.
- `configure.ac` checks every dependency and stops with a clear message if one
  is missing or too old. It uses `PKG_CHECK_MODULES` where a `pkg-config` file
  exists. asio is header-only, so it is checked by compiling a test that
  includes `<asio.hpp>` and tests `ASIO_VERSION`.

| Dependency        | Minimum | Check in `configure.ac`                              |
|-------------------|---------|------------------------------------------------------|
| asio (standalone) | 1.30.0  | `ASIO_VERSION >= 103000` on `<asio.hpp>`             |
| expat             | 2.5.0   | `PKG_CHECK_MODULES([EXPAT], [expat >= 2.5.0])`       |
| OpenSSL           | 3.0.0   | `PKG_CHECK_MODULES([OPENSSL], [openssl >= 3.0.0])`   |
| SQLite            | 3.40.0  | `PKG_CHECK_MODULES([SQLITE3], [sqlite3 >= 3.40.0])`  |
| Catch2            | 3.3.0   | `PKG_CHECK_MODULES([CATCH2], [catch2-with-main >= 3.3.0])` (tests only) |

- The minimums are no higher than the versions in Debian 13, so Orange builds
  there without backports. asio 1.30 is the version 0002 is written against.
- Raising a minimum changes the table and `configure.ac` in the same commit,
  and the commit message names the feature that needs it.

### Adding a dependency

A new dependency is a project decision, so it gets its own ADR.

1. The ADR is accepted by the deciders listed in it, and only then does
   `configure.ac` change.
2. The ADR justifies:
   - **Need:** what problem it solves, and why the standard library or an
     existing dependency does not.
   - **License:** which license, and why it is compatible with ours when
     linked into oranged and orange-agent. Unclear licenses are rejected.
   - **Debian packaging:** already in Debian stable, in a version that meets
     the minimum we would set. A dependency that exists only as a Git
     repository, a language package manager or a copy in our tree is rejected.
   - **Maintenance:** recent releases, a working security process, and more
     than one maintainer. An abandoned project is rejected.
   - **Risk:** whether it parses untrusted input, how much it adds to the
     build, and which module wraps it so it can be replaced.
3. An optional dependency (for example libsecret, for the client only) has a
   `--enable-` or `--disable-` option in `configure` and is not needed to build
   oranged or run the test suite.
4. The ADR adds the dependency to the table above or points to the ADR that
   did, together with its `configure.ac` check and `debian/control` entry.

## Consequences

- **Positive:** a small set of packages that Debian already ships. TLS and XML
  parsing are in libraries that many others review and fuzz, and that
  distributions patch. Nothing is bundled, so there is nothing for us to
  update by hand. A clear rule for growth.
- **Negative:** minimum versions are limited to what Debian stable ships, so we
  cannot use newer features until they get there. OpenSSL's API needs one small
  wrapper module that is reviewed carefully. Header-only asio makes builds
  slower. SQLite's blocking API forces the design in 0002.
- **Follow-ups:**
  - #17 is closed with a link to this ADR.
  - libsecret, for the client only, is added by
    [0008](0008-credential-storage.md); list it here once 0008 is accepted.
  - `configure.ac` gets the checks in the table.
  - A CI job builds with the minimum versions, so the table cannot drift away
    from what actually works.
- **Revisit when:** a dependency changes its license or loses its maintainers,
  Debian stable drops a package we rely on, the C++ standard library ships
  networking that could replace asio, or a security problem in a dependency
  makes one of these choices wrong.