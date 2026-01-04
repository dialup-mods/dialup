include tools/build-tools/make/common.mk
include tools/build-tools/make/shell.mk

EXCEPTION_FILE    := tools/build-tools/shell-exception.txt

.PHONY: check-shell help install configure build clean

DIALUP_ROOT := $(LOCALAPPDATA)/DialUp

CMAKE_BUILD_TOOLS_SRC := tools/build-tools
CMAKE_BUILD_TOOLS_BUILD := $(CMAKE_BUILD_TOOLS_SRC)/build

install-tools: check-shell
	@bash -lc 'cd core/include/external && git submodule update --init --recursive'
	@bash -lc 'mkdir -vp "$$LOCALAPPDATA/DialUp/include/v1"'
	@bash -lc 'mkdir -vp "$$LOCALAPPDATA/DialUp/include/external/fkYAML/include"'
	@bash -lc 'mkdir -vp "$$LOCALAPPDATA/DialUp/include/external/fmt/include"'
	@bash -lc 'mkdir -vp "$$LOCALAPPDATA/DialUp/include/external/doctest/include"'
	@bash -lc 'cp -v core/include/v1/*.h "$(LOCALAPPDATA)/DialUp/include/v1"'
	@bash -lc 'cp -v core/include/DialUpPlugin.h "$(LOCALAPPDATA)/DialUp/include"'
	@bash -lc 'cp -rv core/include/external/doctest/* "$(DIALUP_ROOT)/include/external/fkYAML/include"'
	@bash -lc 'cp -rv core/include/external/fkYAML/include/* "$(DIALUP_ROOT)/include/external/fkYAML/include"'
	@bash -lc 'cp -rv core/include/external/fmt/include/* "$(DIALUP_ROOT)/include/external/fmt/include"'
	cmake -S $(CMAKE_BUILD_TOOLS_SRC) -B $(CMAKE_BUILD_TOOLS_BUILD) \
	  -Wno-dev -DCMAKE_INSTALL_PREFIX="$(DIALUP_ROOT)"
	cmake --build $(CMAKE_BUILD_TOOLS_BUILD)
	cmake --install $(CMAKE_BUILD_TOOLS_BUILD)

check: check-shell
	@echo off
	if not exist "%LOCALAPPDATA%\DialUpFramework\build-rules" (
	  echo DialUp BuildRules not installed.
	  echo Run: make install-buildrules
	  exit /b 1
	)

# Default target - show help on first run
help:
	@if [ ! -f .installed ]; then \
		echo "DialUp - First Time Setup"; \
		echo ""; \
		echo "Installation:"; \
	else \
		echo "DialUp Build System"; \
		echo ""; \
		echo "Targets:"; \
		echo "  make sdk-gen    - Build SDK Generator"; \
		echo "  make sdk        - Build SDK (requires generated code)"; \
		echo "  make framework  - Build Framework"; \
		echo "  make plugins    - Build example plugins"; \
		echo "  make clean      - Clean all builds"; \
		echo ""; \
		echo "Documentation: https://docs.dialup.now"; \
	fi

mark-installed:
	@touch .installed

clean:
	rm -f .installed
