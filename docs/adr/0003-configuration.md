<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0003. Configuration format for the server and the client

- **Status:** Proposed
- **Date:** 2026-10-22
- **Deciders:** mb6ockatf
- **Issue:** #8

## Context

oranged needs a configuration file from 0.1 on (#92), and orange-agent
needs one for its accounts (#99). Both are read by people and edited by
hand, and administrators will keep them across upgrades, so the format
is hard to change once released.

Forces and constraints:

- Server configuration covers virtual hosts, TLS certificates,
  listeners, and modules with their own options.
- Client configuration covers accounts; credentials need protection.
- Every parser library is one more build dependency for distributions
  to package; writing our own is code to fuzz and maintain.
- Errors in the file must be reported clearly, with line numbers, as
  decided in [0001](0001-error-handling.md).

Questions this ADR must answer:

- [ ] #55 Format: TOML, INI-style, a custom format? Which parser library
  (one more dependency) or our own?
- [ ] #56 Server: `/etc/orange/oranged.conf`; virtual hosts, TLS
  certificates, listeners, modules and their options.
- [ ] #57 Client: `$XDG_CONFIG_HOME/orange/` for accounts, but where do
  passwords go?
- [ ] #58 Reload without restart (SIGHUP) for the server: in scope for
  0.1?
- [ ] #59 Unknown keys: error or warning?

## Options considered

1. **TOML with an existing parser library.**
   - Pros: ...
   - Cons: ...
2. **INI-style format.**
   - Pros: ...
   - Cons: ...
3. **A custom format with our own parser.**
   - Pros: ...
   - Cons: ...
4. **Do nothing (command-line options only).**
   - Cons: ...

## Decision

We will ...

Why this option beats the others, tied back to the forces in Context.

## Example

A complete configuration for a single-domain server:

```
...
```

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Follow-ups:**
  - Configuration file loading (#92) and account configuration (#99).
  - The configuration reference in the manual (#108).
- **Revisit when:** ...
