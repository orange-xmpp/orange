# Contributing to Orange

## Workflow

- Every change goes through a pull request against `master`.
- A pull request needs two approvals; at least one from a maintainer for
  changes to architecture (module interfaces, the agent socket protocol,
  storage interfaces, the build system).
- Every pull request carries its own tests and documentation (Texinfo
  manual, man pages, NEWS for user-visible changes).
- CI must pass: `make distcheck` with `--enable-werror`, on the minimum
  and the newest supported compiler.

## Developer Certificate of Origin

Sign off every commit (`git commit -s`), certifying the
[Developer Certificate of Origin](https://developercertificate.org/):
you wrote the change, or have the right to submit it under the license
of the files it touches.

## Licenses

Each source file starts with SPDX lines naming its license:

| Directory | License | SPDX identifier |
|---|---|---|
| `server/` | GNU AGPL v3 or later | `AGPL-3.0-or-later` |
| `client/` | GNU GPL v3 or later | `GPL-3.0-or-later` |
| `lib/` | GNU LGPL v3 or later | `LGPL-3.0-or-later` |
| `docs/` | GNU FDL v1.3 or later, no invariant sections | `GFDL-1.3-no-invariants-or-later` |

```cpp
// SPDX-License-Identifier: LGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 The Orange authors
```

Tests use the license of the code they test.

## Compilers

The minimum is GCC 14, or Clang 18 with libstdc++ 14. Do not use C++23
features that the minimum lacks, such as `std::flat_map` or `import std`;
CI builds with the minimum compiler to catch that.

`ORANGE_CXX23` (`m4/orange_cxx23.m4`) checks for the features Orange
uses (`std::expected` with monadic operations, `std::print`, deducing
`this`), not just for a `-std=` option being accepted: GCC 13 accepts
`-std=c++23` but has no `<print>`. It tries the compiler as it is, then
`-std=c++23`, then `-std=c++2b`, and appends the first one that works to
`CXX`. Before that it removes any `-std=` option already in `CXX`,
because Autoconf 2.72's `AC_PROG_CXX` adds `-std=gnu++11` with compilers
whose default dialect fails its C++11 probe (GCC 16 does).

`ORANGE_WARNINGS` (`m4/orange_warnings.m4`) keeps each warning option
from its list only if the compiler accepts it with `-Werror`, because
Clang only warns about unknown options.

## Comments

No comments in C++ sources, `configure.ac` or m4 files; the only
exception is the SPDX license header. Explain things in this file, the
Texinfo manual or the man pages instead.

## Code style

GNU style, as in `.clang-format`. Format before you push:

```sh
clang-format -i $(git ls-files '*.cpp' '*.hpp')
```

## Building and testing

```sh
./autogen.sh
./configure --enable-werror --enable-sanitizers
make -j"$(nproc)" check
make distcheck
```

Unit tests are Catch2 programs in `tests/`, run through automake's TAP
driver; add new ones to `tests/local.mk`.

## Git hooks

Enable the project's hooks once per clone:

```sh
git config core.hooksPath .githooks
```

The pre-commit hook rewraps the Markdown files under `docs/adr/` to 80
columns with `.githooks/md-wrap.awk`; headings, tables, HTML comments,
block quotes and code blocks stay as they are. Changes you have not
staged stay unstaged. To rewrap a file by hand:

```sh
awk -f .githooks/md-wrap.awk FILE > FILE.new && mv FILE.new FILE
```

## Layout

Each component keeps its build rules in its own `local.mk`, included by
the top-level `Makefile.am`:

- `lib/` — liborange, protocol code shared by the server and the client
- `server/core/`, `server/modules/`, `server/storage/` — oranged
- `client/core/`, `client/agent/`, `client/cli/`, `client/repl/` — the client
- `tests/` — unit tests and test helpers
- `docs/` — Texinfo manual and man pages
