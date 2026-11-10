<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# Architecture decision records

An architecture decision record (ADR) writes down one decision that is hard to
change later: what we decided, which options we weighed, and what it costs us.
Specifications (`docs/spec/`) describe how something works; an ADR explains why
we chose it.

## Writing an ADR

1. Take the next free number and copy [template.md](template.md) to
   `NNNN-slug.md` (four digits, lowercase slug with hyphens).
2. Fill in Context and Options considered first. Keep the Decision empty until
   the options are compared.
3. Open a pull request with status **Proposed** and link the issue.
4. The pull request needs two approvals, one of them from the architect
   (enforced by CODEOWNERS on `docs/adr/`). Before merging, set the status to
   **Accepted** and the date to the day of the merge.

Numbers are never reused. An accepted ADR is not rewritten: to change a
decision, write a new ADR and mark the old one **Superseded by
[NNNN](NNNN-slug.md)**. Typos and broken links may be fixed in place.

## Translations

Every ADR is written in English first; the English file is the authoritative
version. A Russian translation lives next to it with a `.ru` suffix:
`0001-error-handling.md` and `0001-error-handling.ru.md`. A translation may be
added at any time after the English version is merged, and an ADR without one is
complete.

A translation starts with the same header block as the original, plus one line
naming the commit of the English file it was translated from:

```
- **Translated from:** 0001-error-handling.md at commit `abc1234`
```

When the English file changes after that commit, the translation is outdated:
update it and the commit, or leave it and let the index show it as outdated.
Only the English file decides the status; a translation copies it.

## Status

| Status | Meaning |
|---|---|
| Proposed | Under discussion in a pull request or an issue. |
| Accepted | In force; code and specs follow it. |
| Withdrawn | Dropped before it was accepted; the number stays unused. |
| Deprecated | No longer applies, and nothing replaces it. |
| Superseded | Replaced by a later ADR, linked from the status line. |

## Index

The Russian column is empty, links to the translation, or says "outdated" next
to the link.

| ADR | Title | Status | Issue | Russian |
|---|---|---|---|---|
| [0001](0001-error-handling.md) | Error handling | Accepted | #2 | |
| [0002](0002-concurrency.md) | Concurrency model | Proposed | #3 | |
| [0003](0003-configuration.md) | Configuration format for the server and the client | Proposed | #8 | |
| [0004](0004-monorepo-autotools.md) | Keep everything in one repository, built with Autotools | Proposed | #114 | |
| [0005](0005-cxx23.md) | Use C++23, with GCC 14 and Clang 18 as the minimum | Proposed | #115 | |
| 0006 | License each component separately | Withdrawn | #117 | |
| [0007](0007-dependencies.md) | Build on asio, expat, OpenSSL, SQLite and Catch2 | Proposed | #116 | |
| [0008](0008-credential-storage.md) | Credential storage in orange-agent | Proposed | #118 | |
| [0009](0009-module-loading.md) | How server modules are built and loaded | Proposed | #119 | |
| [0010](0010-agent-protocol-framing.md) | Agent socket protocol framing and versioning | Proposed | #120 | |
| [0011](0011-jid-precis.md) | JID parsing and PRECIS normalization | Proposed | #121 | |
