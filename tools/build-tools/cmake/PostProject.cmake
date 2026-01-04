if (NOT TARGET ${PROJECT_NAME})
  message(FATAL_ERROR
    "DialUpBuildRules: Expected primary target '${PROJECT_NAME}' to exist")
endif()

get_property(_all_targets GLOBAL PROPERTY TARGETS)
list(LENGTH _all_targets _target_count)

if (_target_count GREATER 1)
  message(FATAL_ERROR
    "DialUpBuildRules assumes a single-target project. Found: ${_all_targets}")
endif()

if (NOT DIALUP_PREPROJECT_LOADED)
  message(FATAL_ERROR
    "DialUp BuildRules: PreProject.cmake must be included before project()")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(compile_options
    /std:c++20
    /bigobj
    /EHsc
    /MP
    /utf-8
    /Zi # generate debug info
)

target_compile_options(${PROJECT_NAME} PRIVATE ${compile_options})
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_20)

target_compile_definitions(${PROJECT_NAME} PRIVATE FMT_HEADER_ONLY)
target_compile_definitions(${PROJECT_NAME} PRIVATE WIN32_LEAN_AND_MEAN)
target_compile_definitions(${PROJECT_NAME} PRIVATE NOMINMAX)
