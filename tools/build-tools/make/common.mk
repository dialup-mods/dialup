PROBABLYMICROSOFT := 1
ifeq ($(strip $(MSYSTEM)),)
	PROBABLYMICROSOFT := 0
endif

LOCALAPPDATA      := $(shell powershell -NoProfile -Command "[Environment]::GetFolderPath('LocalApplicationData')")

DIALUP_ROOT       := $(LOCALAPPDATA)/DialUp
BUILD_RULES_DIR   := $(DIALUP_ROOT)/build-rules

EXCEPTION_FILE    := $(BUILD_RULES_DIR)/shell-exception.txt
CONFIG_COMMON     := $(BUILD_RULES_DIR)/make/common.mk
CONFIG_SHELL      := $(BUILD_RULES_DIR)/make/shell.mk

VCVARS         := C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\VC\\Auxiliary\\Build\\vcvars64.bat

GENERATOR      := Ninja
MAKEFLAGS      += --no-print-directory
INJECTOR       := $(LOCALAPPDATA)/DialUp/bin/DialUpInjector.exe

define run_with_vcvars
	cmd /C "$(VCVARS)" & $(1)
endef
