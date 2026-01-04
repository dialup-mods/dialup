# find/set game path
set(GAME_BINARY_PATH CACHE STRING "path of the game's executable")
if(NOT GAME_BINARY_PATH)
	if(DEFINED ENV{platform} AND "$ENV{platform}" STREQUAL "steam")
		set(GAME_BINARY_PATH "C:/Program Files (x86)/Steam/steamapps/common/rocketleague/Binaries/Win64")
	else()
		set(GAME_BINARY_PATH "C:/Program Files/Epic Games/rocketleague/Binaries/Win64")
	endif()
endif()
