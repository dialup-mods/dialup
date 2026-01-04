#
# The SDK plugin, not the generator
#
function(dialup_setup_sdk name)
    set(oneValueArgs DESTINATION)
    set(multiValueArgs SOURCES INCLUDES)

    cmake_parse_arguments(
        SDK "" "DESTINATION" "SOURCES;INCLUDES" ${ARGN}
    )

    add_library(${name} SHARED ${SDK_SOURCES})
    set(CMAKE_INSTALL_PREFIX "${DIALUP_DIR}" CACHE PATH "DialUp install root" FORCE)

    target_include_directories(${name}
        PRIVATE ${SDK_INCLUDES}
        PUBLIC $<INSTALL_INTERFACE:include>
    )

    install(
	DIRECTORY ${SDK_INCLUDES}/
	DESTINATION ${SDK_DESTINATION}/include
        FILES_MATCHING PATTERN "*.h"
    )

    install(TARGETS ${name}
        EXPORT ${name}Targets
        RUNTIME DESTINATION ${SDK_DESTINATION}/bin
	LIBRARY DESTINATION ${SDK_DESTINATION}/bin
        ARCHIVE DESTINATION ${SDK_DESTINATION}/bin
    )
    
    # Package config
    include(CMakePackageConfigHelpers)
    
    configure_package_config_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/CMakeConfig.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${name}Config.cmake
        INSTALL_DESTINATION ${SDK_DESTINATION}
    )
    
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${name}ConfigVersion.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${name}Config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${name}ConfigVersion.cmake
        DESTINATION ${SDK_DESTINATION}
    )
    
    install(EXPORT ${name}Targets
        FILE ${name}Targets.cmake
        NAMESPACE ${name}::
        DESTINATION ${SDK_DESTINATION}
    )

    include("${DIALUP_DIR}/build-tools/PostProject.cmake")

endfunction()
