set(DIALUP_DIR "$ENV{LOCALAPPDATA}/DialUp")
set(DIALUP_PLUGIN_DIR "$ENV{LOCALAPPDATA}/DialUp/plugin")
set(BAKKESMOD_PREFIX "$ENV{APPDATA}/bakkesmod/bakkesmod/plugins" CACHE PATH "BakkesMod plugin path" FORCE)

# warning about trying to build in an unsupported terminal. microsoft is truly the worst dev env
execute_process(COMMAND cl RESULT_VARIABLE CL_RESULT OUTPUT_QUIET ERROR_QUIET)
if(NOT CL_RESULT EQUAL 0)
	file(READ "${DIALUP_DIR}/build-rules/shell-exception.txt" EXCEPTION_MSG)
    string(REPLACE "\n" ";" EXCEPTION_LINES "${EXCEPTION_MSG}")
    message("")
    message("===========================================")
    foreach(line IN LISTS EXCEPTION_LINES)
        message("${line}")
    endforeach()
    message("===========================================")
    message(FATAL_ERROR "⛔ MSVC environment not detected.")
endif()

get_property(_targets GLOBAL PROPERTY TARGETS)
if (_targets)
  message(FATAL_ERROR
    "DialUpBuildRules PreProject.cmake must be included before project()")
endif()

set(CMAKE_C_COMPILER
    "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/cl.exe"
    CACHE FILEPATH "C Compiler" FORCE
)
set(CMAKE_CXX_COMPILER
    "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/cl.exe"
    CACHE FILEPATH "C++ Compiler" FORCE
)
set(CMAKE_LINKER
    "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/link.exe"
    CACHE FILEPATH "Linker" FORCE
)

set(CMAKE_BUILD_TYPE RelWithDebInfo)
set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING "" FORCE)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")  # `/MD`
set(CMAKE_GENERATOR_TOOLSET "v142" CACHE STRING "Toolset version")


set(DIALUP_PREPROJECT_LOADED TRUE CACHE INTERNAL "")
