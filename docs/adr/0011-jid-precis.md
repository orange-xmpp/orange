<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0011. JID parsing and PRECIS normalization

- **Status:** Proposed
- **Date:** 2026-10-26
- **Deciders:** mb6ockatf
- **Issue:** #121
- **Blocks:** #4, #34

## Context

Every address in XMPP is a JID, and two JIDs are equal only after normalization
(RFC 7622): PRECIS profiles (RFC 8264, 8265, 8266) for the local and resource
parts, IDNA for the domain. Getting it wrong lets two accounts look the same,
which is a security problem. Normalization depends on Unicode tables that change
with new Unicode versions.

Questions this ADR must answer:

- [ ] PRECIS and IDNA: our own implementation, libidn2, ICU, or another library?
- [ ] Unicode version, and how we keep the tables up to date.
- [ ] Cost of each option: dependency size, license, fuzzing surface.

## Options considered

1. **libidn2 for domains, our own PRECIS.**
   - Pros: ...
   - Cons: ...
2. **ICU for both.**
   - Pros: ...
   - Cons: ...
3. **Our own implementation of both.**
   - Pros: ...
   - Cons: ...

## Decision

We will ...

Why this option beats the others, tied back to the forces in Context.

## Consequences

- **Positive:** ...
- **Negative:** ...
- **Follow-ups:** the XML stream spec (#4) and `orange::jid` (#34) follow this
  ADR.
- **Revisit when:** ...
