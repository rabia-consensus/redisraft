# This file is part of RedisRaft.
#
# Copyright (c) 2020 Redis Labs
#
# RedisRaft is dual licensed under the GNU Affero General Public License version 3
# (AGPLv3) or the Redis Source Available License (RSAL).

OS := $(shell sh -c 'uname -s 2>/dev/null || echo none')
BUILDDIR := $(CURDIR)/.build

ifeq ($(OS),Linux)
    ARCH_CFLAGS := -fPIC
    ARCH_LDFLAGS := -shared -Wl,-Bsymbolic-functions
else
    ARCH_CFLAGS := -dynamic
    ARCH_LDFLAGS := -bundle -undefined dynamic_lookup
endif

CC = gcc
CPPFLAGS = -D_POSIX_C_SOURCE=200112L -D_GNU_SOURCE
ifneq ($(TRACE),)
    CPPFLAGS += -DENABLE_TRACE
endif
CFLAGS = -g -Wall -std=c99 -I$(BUILDDIR)/include $(ARCH_CFLAGS)
LDFLAGS = $(ARCH_LDFLAGS)

LIBS = \
       $(BUILDDIR)/lib/libraft.a \
       $(BUILDDIR)/lib/libhiredis.a \
       $(BUILDDIR)/lib/libuv.a \
       -lpthread

OBJECTS = \
	  redisraft.o \
	  common.o \
	  node.o \
	  node_addr.o \
	  join.o \
	  util.o \
	  config.o \
	  raft.o \
	  snapshot.o \
	  log.o \
	  proxy.o \
	  serialization.o \
	  cluster.o \
	  crc16.o \
	  connection.o \
	  commands.o

ifeq ($(COVERAGE),1)
CFLAGS += -fprofile-arcs -ftest-coverage
LIBS += -lgcov
endif

.PHONY: all
all: redisraft.so

buildinfo.h:
	GIT_SHA1=`(git show-ref --head --hash=8 2>/dev/null || echo 00000000) | head -n1` && \
	echo "#define REDISRAFT_GIT_SHA1 \"$$GIT_SHA1\"" > buildinfo.h

$(OBJECTS): | $(BUILDDIR)/.deps_installed buildinfo.h

redisraft.so: $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS) $(LIBS)

clean: clean-tests
	rm -f redisraft.so buildinfo.h $(OBJECTS)

cleanall: clean
	rm -rf $(BUILDDIR)
	$(MAKE) -C deps clean PREFIX=$(BUILDDIR)

# ----------------------------- Unit Tests -----------------------------

DUT_CPPFLAGS = $(CPPFLAGS) -include tests/dut_premble.h
ifeq ($(OS),Linux)
    DUT_CFLAGS = $(CFLAGS) -fprofile-arcs -ftest-coverage
    DUT_LIBS = -lgcov
else
    DUT_CFLAGS = $(CFLAGS)
    DUT_LIBS =
endif
TEST_OBJECTS = \
	tests/main.o \
	tests/test_log.o \
	tests/test_util.o \
	tests/test_serialization.o
DUT_OBJECTS = \
	$(patsubst %.o,tests/test-%.o,$(OBJECTS))
TEST_LIBS = $(BUILDDIR)/lib/libcmocka-static.a $(DUT_LIBS) -lpthread

.PHONY: clean-tests
clean-tests:
	-rm -rf tests/tests_main $(DUT_OBJECTS) $(TEST_OBJECTS) *.gcno *.gcda tests/*.gcno tests/*.gcda tests/*.gcov tests/*lcov.info tests/.*lcov_html

tests/test-%.o: %.c
	$(CC) -c $(DUT_CFLAGS) $(DUT_CPPFLAGS) -o $@ $<

.PHONY: tests
tests: unit-tests integration-tests

.PHONY: unit-tests
ifeq ($(OS),Linux)
unit-tests: tests/tests_main
	./tests/tests_main && \
		lcov --rc lcov_branch_coverage=1 -c -d . -d ./tests --no-external -o tests/lcov.info && \
		lcov --rc lcov_branch_coverage=1 --summary tests/lcov.info
else
unit-tests: tests/tests_main
	./tests/tests_main
endif

.PHONY: tests/tests_main
tests/tests_main: $(TEST_OBJECTS) $(DUT_OBJECTS)
	$(CC) -o tests/tests_main $(TEST_OBJECTS) $(DUT_OBJECTS) $(LIBS) $(TEST_LIBS)

.PHONY: unit-lcov-report
unit-lcov-report: tests/lcov.info
	mkdir -p tests/.lcov_html
	genhtml --branch-coverage -o tests/.lcov_html tests/lcov.info
	xdg-open tests/.lcov_html/index.html >/dev/null 2>&1

# ----------------------------- Integration Tests -----------------------------

PYTEST_OPTS ?= -v

.PHONY: integration-tests
integration-tests:
	pytest tests/integration $(PYTEST_OPTS)

.PHONY: valgrind-tests
valgrind-tests:
	pytest tests/integration $(PYTEST_OPTS) --valgrind

.PHONY: integration-lcov-report
integration-lcov-report:
	lcov --rc lcov_branch_coverage=1 -c -d . --no-external -o tests/integration-lcov.info && \
	lcov --rc lcov_branch_coverage=1 --summary tests/integration-lcov.info
	mkdir -p tests/.integration-lcov_html
	genhtml --branch-coverage -o tests/.integration-lcov_html tests/integration-lcov.info
	xdg-open tests/.integration-lcov_html/index.html >/dev/null 2>&1

# ------------------------- Build dependencies -------------------------

$(BUILDDIR)/.deps_installed:
	mkdir -p $(BUILDDIR)
	mkdir -p $(BUILDDIR)/lib
	mkdir -p $(BUILDDIR)/include
	$(MAKE) -C deps PREFIX=$(BUILDDIR)
	touch $(BUILDDIR)/.deps_installed
