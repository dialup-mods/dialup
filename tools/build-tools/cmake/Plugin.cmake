function(dialup_setup_module name)
    set(oneValueArgs DESTINATION)
    set(multiValueArgs SOURCES INCLUDES)
    cmake_parse_arguments(MODULE "" "DESTINATION" "SOURCES;INCLUDES" ${ARGN})
    
    # Default destination if not provided
    if(NOT MODULE_DESTINATION)
        set(MODULE_DESTINATION "plugin/${name}")
    endif()
    
    # Normalize the full install path
    file(TO_CMAKE_PATH "${DIALUP_DIR}" DIALUP_DIR_NORMALIZED)
    set(CMAKE_INSTALL_PREFIX "${DIALUP_DIR_NORMALIZED}" CACHE PATH "Install root" FORCE)
    
    
    add_library(${name} SHARED ${MODULE_SOURCES})
    
    target_include_directories(${name}
        PRIVATE ${MODULE_INCLUDES}
        PUBLIC $<INSTALL_INTERFACE:include>
    )
    
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/include)
        install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
                DESTINATION ${MODULE_DESTINATION}/include
                FILES_MATCHING PATTERN "*.h")
    endif()
    
    install(TARGETS ${name}
        EXPORT ${name}Targets
        RUNTIME DESTINATION ${MODULE_DESTINATION}/bin
        LIBRARY DESTINATION ${MODULE_DESTINATION}/bin
        ARCHIVE DESTINATION ${MODULE_DESTINATION}/bin
    )
    
    # Package config
    include(CMakePackageConfigHelpers)
    
    configure_package_config_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/CMakeConfig.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${name}Config.cmake
        INSTALL_DESTINATION ${MODULE_DESTINATION}
    )
    
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${name}ConfigVersion.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion
    )
    
    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${name}Config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${name}ConfigVersion.cmake
        DESTINATION ${MODULE_DESTINATION}
    )
    
    install(EXPORT ${name}Targets
        FILE ${name}Targets.cmake
        NAMESPACE ${name}::
        DESTINATION ${MODULE_DESTINATION}
    )
    
    install(FILES $<TARGET_PDB_FILE:${name}>
            DESTINATION ${MODULE_DESTINATION}/bin
            OPTIONAL)
    
    include("${DIALUP_DIR}/build-tools/PostProject.cmake")
endfunction()
