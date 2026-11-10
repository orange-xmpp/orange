# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 The Orange authors

# The client.  GPL-3.0-or-later.
#
#   client/core/   headless client logic shared by everything below
#   client/agent/  orange-agent: holds XMPP sessions, serves a unix socket
#   client/cli/    orange-cli: thin subcommands that talk to the agent
#   client/repl/   the interactive mode of orange-cli, also an agent client

if ENABLE_CLIENT
noinst_LTLIBRARIES += client/core/libclientcore.la
bin_PROGRAMS += client/agent/orange-agent client/cli/orange-cli
dist_man_MANS += docs/orange-agent.1 docs/orange-cli.1
endif

client_core_libclientcore_la_SOURCES = \
	client/core/socket_path.cpp \
	client/core/socket_path.hpp

client_agent_orange_agent_SOURCES = client/agent/main.cpp
client_agent_orange_agent_CPPFLAGS = $(AM_CPPFLAGS) $(SQLITE3_CFLAGS) \
	$(LIBSECRET_CFLAGS)
client_agent_orange_agent_LDADD = \
	client/core/libclientcore.la \
	lib/liborange.la \
	$(SQLITE3_LIBS) \
	$(LIBSECRET_LIBS)

client_cli_orange_cli_SOURCES = \
	client/cli/main.cpp \
	client/repl/repl.cpp \
	client/repl/repl.hpp
client_cli_orange_cli_LDADD = \
	client/core/libclientcore.la \
	lib/liborange.la
