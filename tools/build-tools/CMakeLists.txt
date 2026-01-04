cmake_minimum_required(VERSION 4.0)
set(DIALUP_DIR "$ENV{LOCALAPPDATA}/DialUp")
set(BUILD_RULES_DIR "${DIALUP_DIR}/build-tools")

project(DialUpBuildRules VERSION 1.0 LANGUAGES NONE)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(
    FILES
	${CMAKE_CURRENT_SOURCE_DIR}/cmake/GameBinaryDir.cmake
	${CMAKE_CURRENT_SOURCE_DIR}/cmake/SDK.cmake
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Plugin.cmake
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/PostBuild.cmake
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/PostProject.cmake
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/PreProject.cmake
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Tidy.cmake
        ${CMAKE_CURRENT_SOURCE_DIR}/make/common.mk
        ${CMAKE_CURRENT_SOURCE_DIR}/make/shell.mk
        ${CMAKE_CURRENT_SOURCE_DIR}/make/rocketleague.mk
        ${CMAKE_CURRENT_SOURCE_DIR}/shell-exception.txt
    DESTINATION
        ${BUILD_RULES_DIR}
)

configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/BuildRulesConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/BuildRulesConfig.cmake
    INSTALL_DESTINATION
        ${BUILD_RULES_DIR}
    NO_SET_AND_CHECK_MACRO
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/BuildRulesConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        ${CMAKE_CURRENT_BINARY_DIR}/BuildRulesConfig.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/BuildRulesConfigVersion.cmake
    DESTINATION
        ${BUILD_RULES_DIR}
)
