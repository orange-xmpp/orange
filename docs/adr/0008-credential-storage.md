<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0008. Credential storage in orange-agent

- **Status:** Proposed
- **Date:** 2026-10-26
- **Deciders:** mb6ockatf
- **Issue:** #118
- **Blocks:** #8, #99

## Context

orange-agent logs in to XMPP accounts without asking the user each time, so it
must keep something that proves the user's identity. If that leaks, the account
is lost. The agent runs both on desktops (with a keyring) and on headless
machines (without one).

Questions this ADR must answer:

- [x] Where account passwords live: a desktop keyring (Secret Service), a
  separate file with mode 0600, the configuration file, or nowhere (prompt on
  start)?
- [x] Store the password, or SCRAM salted keys only?
- [x] Behavior on a headless machine without a keyring.
- [x] How SECURITY.md describes the threat model for the agent.

## Options considered

1. **Desktop keyring (Secret Service API).**
   - Pros: easy for the user; credentials are encrypted at rest.
   - Cons: depends on libsecret and a D-Bus session; no protection against
     malware running as the same user.
2. **A separate credentials file with mode 0600.**
   - Pros: works everywhere, including headless machines; stays out of
     configuration files that people share or commit to dotfile repositories.
   - Cons: stored in plain text; readable by any process running as the same
     user.
3. **Passwords in the configuration file.**
   - Pros: one file to set up.
   - Cons: stored in plain text; configuration files get shared and committed to
     dotfile repositories, and the password leaks with them.
4. **Passwords in environment variables.**
   - Pros: easy to pass to an automated setup.
   - Cons: inherited by every child process, readable through
     `/proc/PID/environ`, and copied into logs; the variable is usually set from
     a plain-text file anyway.
5. **Nothing stored; prompt when the agent starts.**
   - Pros: safest; easiest to implement.
   - Cons: least comfortable for the user; impossible for automated setups with
     nobody to answer.
6. **Store SCRAM salted keys instead of the password** (combines with any of the
   above).
   - Pros: a leak does not reveal the password, so accounts on other services
     that reuse it stay safe.
   - Cons: the keys stop working when the server changes the salt or the
     iteration count; each SCRAM mechanism needs its own keys; no fallback to
     PLAIN.

## Decision

Credentials live in the desktop keyring, through the Secret Service D-Bus API
(libsecret). On machines without a Secret Service, such as automated setups with
no desktop session, the agent reads the password from the file named by
`ORANGE_PASSWORD_FILE`, and refuses a file whose mode allows access to anyone
but its owner (anything other than 0600 or 0400). The agent never takes the
password itself from an environment variable.

We store SCRAM salted keys, not the password. A thief can still log in to this
account with them, but does not learn the password, so other services where the
user reuses it stay safe. When the stored keys stop working, the agent asks for
the password again and derives new keys.

The threat model is in [SECURITY.md](../../SECURITY.md): the agent protects
credentials at rest, not against malware running as the same user.

The keyring is the most comfortable option for most users, while keeping
credentials encrypted at rest. The password file covers headless and automated
setups without the leaks of environment variables, and the SCRAM keys limit the
damage of any leak to one account.

## Consequences

- **Positive:** credentials are encrypted at rest on desktops; no password
  prompt on desktops; headless and automated setups work; a leak never reveals
  the password itself.
- **Negative:** a new dependency (libsecret); a D-Bus session is needed for the
  keyring; on headless machines the password file is plain text, protected only
  by its mode; the agent must handle keys that stop working; CI tests need a
  keyring (run `gnome-keyring-daemon` in CI, or use a fake).
- **Follow-ups:**
  - [0003](0003-configuration.md) refers to this ADR for passwords.
  - [0007](0007-dependencies.md) lists libsecret.
  - `PKG_CHECK_MODULES` for `libsecret-1` in `configure.ac`.
  - The agent protocol (#7, [0010](0010-agent-protocol-framing.md)) carries the
    password request to orange-cli, because the agent has no terminal to ask on:
    when an account is added, and when stored keys stop working.
  - `ORANGE_PASSWORD_FILE` is documented in the manual and in the orange-agent
    man page.
- **Revisit when:** a major user group has no Secret Service (for example,
  headless deployments become the main use case).
