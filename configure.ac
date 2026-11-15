# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 The Orange authors
AC_PREREQ([2.71])
AC_INIT([orange], [0.0.1],
  [https://github.com/orange-xmpp/orange/issues], [orange],
  [https://github.com/orange-xmpp/orange])
AC_CONFIG_SRCDIR([lib/version.cpp])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIRS([m4])
AC_REQUIRE_AUX_FILE([tap-driver.sh])
AM_INIT_AUTOMAKE([1.16 gnits subdir-objects dist-xz -Wall -Werror])
AM_SILENT_RULES([yes])
AC_PROG_CXX
ORANGE_CXX23
AM_PROG_AR
LT_INIT([disable-static])
PKG_PROG_PKG_CONFIG
AC_ARG_ENABLE([server],
  [AS_HELP_STRING([--disable-server], [do not build oranged])],
  [], [enable_server=yes])
AC_ARG_ENABLE([client],
  [AS_HELP_STRING([--disable-client], [do not build orange-agent and orange-cli])],
  [], [enable_client=yes])
AS_IF([test "x$enable_server$enable_client" = xnono],
  [AC_MSG_ERROR([nothing to build: both the server and the client are disabled])])
AM_CONDITIONAL([ENABLE_SERVER], [test "x$enable_server" = xyes])
AM_CONDITIONAL([ENABLE_CLIENT], [test "x$enable_client" = xyes])
PKG_CHECK_MODULES([EXPAT], [expat >= 2.5])
PKG_CHECK_MODULES([OPENSSL], [openssl >= 3.0])
PKG_CHECK_MODULES([SQLITE3], [sqlite3 >= 3.40])
AS_IF([test "x$enable_client" = xyes],
  [PKG_CHECK_MODULES([LIBSECRET], [libsecret-1 >= 0.21])])
AC_LANG_PUSH([C++])
AC_CHECK_HEADER([asio.hpp], [],
  [AC_MSG_ERROR([standalone asio (asio.hpp) is required; on Debian install libasio-dev])])
AC_LANG_POP([C++])
PKG_CHECK_MODULES([CATCH2], [catch2-with-main >= 3.0],
  [have_catch2=yes],
  [have_catch2=no
   AC_MSG_WARN([Catch2 3 not found: unit tests will not be built])])
AM_CONDITIONAL([HAVE_CATCH2], [test "x$have_catch2" = xyes])
ORANGE_WARNINGS
AC_ARG_ENABLE([werror],
  [AS_HELP_STRING([--enable-werror], [treat compiler warnings as errors])],
  [], [enable_werror=no])
AS_IF([test "x$enable_werror" = xyes],
  [WARN_CXXFLAGS="$WARN_CXXFLAGS -Werror"])
AC_ARG_ENABLE([sanitizers],
  [AS_HELP_STRING([--enable-sanitizers],
    [build with AddressSanitizer and UndefinedBehaviorSanitizer])],
  [], [enable_sanitizers=no])
SANITIZER_FLAGS=
AS_IF([test "x$enable_sanitizers" = xyes],
  [SANITIZER_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer"])
AC_SUBST([SANITIZER_FLAGS])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile lib/liborange.pc])
AC_OUTPUT

AC_MSG_NOTICE([

  $PACKAGE_NAME $PACKAGE_VERSION

  C++ compiler:  $CXX
  warnings:      $WARN_CXXFLAGS
  sanitizers:    $enable_sanitizers
  server:        $enable_server
  client:        $enable_client
  unit tests:    $have_catch2
])
