game     ?= default
platform ?= epic
target   ?= RocketLeague.exe

# set binary_dir unless it was explicitly set via command line
ifeq ($(origin binary_dir), undefined)
ifeq ($(platform), steam)
    binary_dir := C:/Program Files (x86)/Steam/steamapps/common/rocketleague/Binaries/Win64
else ifeq ($(platform), epic)
	binary_dir := C:/Program Files/Epic Games/rocketleague/Binaries/Win64
else
    $(error Unknown platform: $(platform))
endif
endif

