<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0004. Keep everything in one repository, built with Autotools

- **Status:** Proposed
- **Date:** 2026-10-18
- **Deciders:** mb6ockatf, d1mark2
- **Issue:** #114

## Context

Orange has three parts: liborange (protocol code shared by both programs),
oranged and the client. Changes to the protocol touch the library and both
programs at once. The project targets Linux, and is meant to be packaged by
distributions such as Debian.

Questions this ADR must answer:

- [ ] Why one repository for liborange, oranged and the client, rather than
  three.
- [ ] Why Autotools rather than CMake or Meson; why one non-recursive
  `Makefile.am` with a `local.mk` per component.
- [ ] Why gnits strictness (NEWS check, `--help`/`--version` installcheck,
  version format).

## Options considered

1. **One repository, Autotools, non-recursive make.**
   - Pros: ...
   - Cons: ...
2. **One repository, CMake.**
   - Pros: ...
   - Cons: ...
3. **One repository, Meson.**
   - Pros: ...
   - Cons: ...
4. **Separate repositories for liborange, oranged and the client.**
   - Pros: ...
   - Cons: ...

## Decision

We keep liborange, oranged and the client in one repository, built by one
non-recursive Automake `Makefile.am` that includes a `local.mk` per component,
with gnits strictness.

Why this option beats the others: ...

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Follow-ups:** ...
- **Revisit when:** ...
