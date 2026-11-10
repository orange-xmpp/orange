<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0010. Agent socket protocol framing and versioning

- **Status:** Proposed
- **Date:** 2026-10-26
- **Deciders:** mb6ockatf
- **Issue:** #120
- **Blocks:** #7

## Context

orange-cli, the interactive mode and users' own scripts all talk to orange-agent
over a Unix socket. The wire format is a public contract: breaking it breaks
every script, and it is frozen at 1.0. The agent protocol spec (#7) describes
the requests; this ADR decides how they are framed and versioned.

Questions this ADR must answer:

- [ ] Framing: JSON lines, length-prefixed JSON, or a binary format?
- [ ] JSON library: which one, or our own (one more dependency, see
  [0007](0007-dependencies.md))?
- [ ] Versioning: how the handshake negotiates a version; what the agent does
  with an older or newer client; when a change is breaking.

## Options considered

1. **JSON lines (one JSON object per line).**
   - Pros: ...
   - Cons: ...
2. **Length-prefixed JSON.**
   - Pros: ...
   - Cons: ...
3. **A binary format (CBOR, protobuf).**
   - Pros: ...
   - Cons: ...

## Decision

We will ...

Why this option beats the others, tied back to the forces in Context.

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Follow-ups:** the agent protocol spec (#7) refers to this ADR for framing
  and versioning.
- **Revisit when:** ...
