<!-- SPDX-License-Identifier: GFDL-1.3-no-invariants-or-later -->
<!-- SPDX-FileCopyrightText: 2026 The Orange authors -->

# 0009. How server modules are built and loaded

- **Status:** Proposed
- **Date:** 2026-10-28
- **Deciders:** mb6ockatf
- **Issue:** #119
- **Blocks:** #5

## Context

Each XEP oranged supports is a module, so that two people can implement two XEPs
without touching the same code. The module interface spec (#5) describes what a
module can do; this ADR decides how modules reach the server. The module
interface is frozen at 1.0. This ADR also answers #37.

Forces and constraints:

- Adding a module must not mean editing code that other people are editing at
  the same time, beyond one line.
- oranged is sharded ([0002](0002-concurrency.md)): shards share nothing, and a
  module keeps no state shared between shards.
- oranged is built with Autotools, with one non-recursive `local.mk` per
  directory ([0004](0004-monorepo-autotools.md)).
- Performance is the main goal: calling a module for a stanza must cost no more
  than a virtual call.
- Before 1.0 the module interface changes often; modules are written by the same
  people who change the interface, in the same repository.
- No XEP planned so far needs a library that the server does not already link.
- The team is small, and CI time is limited: every build variant is one more
  configuration to test.

Questions this ADR must answer:

- [x] Compiled in only, or loadable `.so` plugins (now or later)?
- [x] If compiled in: how a module registers itself (static registry, explicit
  list), and how `configure` enables or disables modules.
- [x] If plugins later: what in today's interface must stay plugin-friendly, and
  what freezing it at 1.0 means.

## Options considered

1. **Compiled in, registered through a static registry.** Each module defines a
   global object whose constructor adds the module to a registry before `main`
   runs.
   - Pros: adding a module touches no shared file; the module is complete in its
     own directory.
   - Cons: if modules are linked from a static library, the linker drops object
     files that nothing refers to, so a module silently disappears unless the
     library is linked with `--whole-archive`. The order in which global
     constructors of different files run is unspecified, so the registry itself
     needs care. Which modules exist is visible only by reading every module.
2. **Compiled in, listed explicitly in one file.** `server/modules/registry.cpp`
   holds one list with one entry per module: its name, the modules it depends on
   and a factory function that creates an instance.
   - Pros: nothing runs before `main`, and nothing depends on linker behaviour.
     The list shows every module in one place. A missing module is a compile
     error, not a silent gap.
   - Cons: adding a module edits one shared file (one line), which may cause a
     trivial merge conflict when two modules land at the same time.
3. **Loadable `.so` plugins**, found and loaded with `dlopen` at startup.
   - Pros: third parties can ship modules without rebuilding oranged; a
     distribution can package optional modules separately.
   - Cons: the module interface becomes an ABI, so every change before 1.0
     breaks every plugin. C++ types across a `dlopen` boundary only work when
     the server and the plugin are built by the same compiler and standard
     library. Loading, versioning and finding plugins is extra code and extra
     ways to fail at startup, for no user we have today.
4. **Do nothing (each module wires itself into the core as it sees fit).**
   - Cons: the core grows a special case for every XEP, and two people adding
     two modules edit the same core code.

## Decision

We will compile every module into oranged and list them explicitly in one file
(option 2). Modules are enabled and disabled at run time in the configuration,
not at build time. There are no `.so` plugins before 1.0.

Option 2 keeps the one property we need from option 1, that a module lives in
its own directory, at the cost of one line in a shared file. It avoids the
silent failures of static registration, and it costs nothing at run time.
Plugins (option 3) would freeze an interface that we still change every week.

### The registry

- `server/modules/registry.cpp` holds the list of modules. Each entry has:
  - the module's name, used in the configuration (for example `ping`);
  - the names of the modules it needs (for example, a module that announces
    features needs `disco`);
  - a factory function that creates one instance of the module.
- The list is a plain array, built at compile time. Adding a module adds one
  entry and the module's sources to `server/modules/local.mk`.
- Every module lives in its own directory, `server/modules/NAME/`, and depends
  only on the module interface (#5), liborange and the C++ standard library,
  never on another module's internals or on the core's internals.

### Enabling modules

- The configuration ([0003](0003-configuration.md)) lists the enabled modules by
  name. Modules that the protocol requires for a working server are enabled by
  default; the module interface spec (#5) marks which ones.
- At startup, oranged checks the list: an unknown name, or an enabled module
  whose required module is disabled, is a configuration error. oranged logs it
  and exits before it accepts any connection ([0001](0001-error-handling.md)).
- `configure` has no option per module. A module that one day needs a new
  library gets its own `--enable-` option then, in its own ADR.

### Modules and shards

- Every shard calls each enabled module's factory once and owns the instance it
  gets ([0002](0002-concurrency.md)). An instance is only ever used on the shard
  that created it, so it needs no locks.
- State that belongs to one entity (a user, a room) lives on that entity's home
  shard and is reached through the routing component, as 0002 requires. A module
  never keeps global or `static` mutable state.
- Startup creates the instances on every shard before any shard accepts
  connections; shutdown destroys them after the last connection is closed.

### Keeping plugins possible

Plugins are not ruled out after 1.0. Today's code keeps that door open with
three rules:

- A module reaches the server only through the module interface (#5), so that
  interface is the whole contract a plugin would need.
- The factory function is the only way a module is created, which is what a
  plugin would export.
- No exception other than `std::bad_alloc` crosses the module interface
  ([0001](0001-error-handling.md)).

Freezing the interface at 1.0 means that after 1.0, a change that breaks an
existing module needs a new major version. Whether 1.0 also adds `.so` plugins
is decided then, in a new ADR that supersedes this one.

## Consequences

- **Positive:** two people can add two modules in parallel and only meet in one
  line of the registry. Which modules exist is visible in one file. Nothing runs
  before `main`, and calling a module costs one virtual call. One build of
  oranged serves every configuration, so CI tests one binary.
- **Negative:** every module is in the binary, even when disabled. Third parties
  cannot add a module without rebuilding oranged. Each shard holds its own
  instance of every enabled module, so per-module memory grows with the number
  of shards.
- **Follow-ups:**
  - The module interface spec (#5): the module class, the factory signature, the
    registry entry, and which modules are enabled by default. Ping (XEP-0199) is
    its worked example.
  - The `modules` setting in the configuration ([0003](0003-configuration.md)).
  - `server/modules/registry.cpp` and `server/modules/local.mk`, written with
    the first module.
  - A unit test that checks the registry: names are unique, every required
    module exists, and there are no dependency cycles.
  - Close #37 with a link to this ADR.
- **Revisit when:** someone outside the team wants to ship a module, a module
  needs a library the server does not otherwise link, or 1.0 is near.
