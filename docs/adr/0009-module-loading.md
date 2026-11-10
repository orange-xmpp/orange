<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0009. How server modules are built and loaded

- **Status:** Proposed
- **Date:** 2026-10-26
- **Deciders:** mb6ockatf
- **Issue:** #119
- **Blocks:** #5

## Context

Each XEP oranged supports is a module, so that two people can implement two XEPs
without touching the same code. The module interface spec (#5) describes what a
module can do; this ADR decides how modules reach the server. The module
interface is frozen at 1.0.

Questions this ADR must answer:

- [ ] Compiled in only, or loadable `.so` plugins (now or later)?
- [ ] If compiled in: how a module registers itself (static registry, explicit
  list), and how `configure` enables or disables modules.
- [ ] If plugins later: what in today's interface must stay plugin-friendly, and
  what freezing it at 1.0 means.

## Options considered

1. **Compiled in, registered through a static registry.**
   - Pros: ...
   - Cons: ...
2. **Compiled in, listed explicitly in one file.**
   - Pros: ...
   - Cons: ...
3. **Loadable `.so` plugins.**
   - Pros: ...
   - Cons: ...

## Decision

We will ...

Why this option beats the others, tied back to the forces in Context.

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Follow-ups:** the module interface spec (#5) refers to this ADR.
- **Revisit when:** ...
