function(configure_plugin target_name)
    set(PLUGIN_INSTALL_DIR "$ENV{LOCALAPPDATA}/DialUp/plugin/${target_name}" CACHE INTERNAL "")
    set(CMAKE_INSTALL_PREFIX "$ENV{LOCALAPPDATA}/DialUp/plugin/${target_name}" CACHE PATH "Default install path" FORCE)

    install(TARGETS ${target_name}
            EXPORT CMakeTargets
            RUNTIME DESTINATION bin
            LIBRARY DESTINATION bin
            ARCHIVE DESTINATION bin
            INCLUDES DESTINATION include
    )

    # install headers (assumes public headers live in /include)
    install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
            DESTINATION include
            FILES_MATCHING PATTERN "*.h")

    install(EXPORT CMakeTargets
            FILE CMakeTargets.cmake
            NAMESPACE ${target_name}::
            DESTINATION ${PLUGIN_INSTALL_DIR}
    )

    # Set properties for the target to ensure proper import
    set_target_properties(${target_name} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${PLUGIN_INSTALL_DIR}/bin"
        LIBRARY_OUTPUT_DIRECTORY "${PLUGIN_INSTALL_DIR}/bin"
        ARCHIVE_OUTPUT_DIRECTORY "${PLUGIN_INSTALL_DIR}/bin"
        # These properties ensure the import library path is set correctly
        IMPORTED_LOCATION "${PLUGIN_INSTALL_DIR}/bin/${target_name}.dll"
        IMPORTED_IMPLIB "${PLUGIN_INSTALL_DIR}/bin/${target_name}.lib"
        IMPORTED_LOCATION_RELWITHDEBINFO "${PLUGIN_INSTALL_DIR}/bin/${target_name}.dll"
        IMPORTED_IMPLIB_RELWITHDEBINFO "${PLUGIN_INSTALL_DIR}/bin/${target_name}.lib"
    )

#    file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/${target_name}Targets.cmake" "
#    set(_IMPORT_PREFIX \"${PLUGIN_INSTALL_DIR}\")
#    set_target_properties(${target_name}::${target_name} PROPERTIES
#        IMPORTED_IMPLIB \"\${_IMPORT_PREFIX}/bin/${target_name}.lib\"
#        IMPORTED_LOCATION \"\${_IMPORT_PREFIX}/bin/${target_name}.dll\"
#    )
#    unset(_IMPORT_PREFIX)
#    ")

    include(CMakePackageConfigHelpers)

    configure_package_config_file(
            ${CMAKE_CURRENT_SOURCE_DIR}/.CMakeConfig.cmake.in
            ${CMAKE_CURRENT_BINARY_DIR}/${target_name}Config.cmake
            INSTALL_DESTINATION ${PLUGIN_INSTALL_DIR}
    )

    write_basic_package_version_file(
            ${CMAKE_CURRENT_BINARY_DIR}/${target_name}ConfigVersion.cmake
            VERSION ${PROJECT_VERSION}
            COMPATIBILITY SameMajorVersion
    )

    install(FILES
            ${CMAKE_CURRENT_BINARY_DIR}/${target_name}Config.cmake
            ${CMAKE_CURRENT_BINARY_DIR}/${target_name}ConfigVersion.cmake
            DESTINATION ${PLUGIN_INSTALL_DIR}
    )

    install(FILES
            $<TARGET_PDB_FILE:${target_name}>
            DESTINATION ${PLUGIN_INSTALL_DIR}/bin
            OPTIONAL
    )

endfunction()

function(dialup_setup_plugin name)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs SOURCES INCLUDES)
    cmake_parse_arguments(PLUGIN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    add_library(${name} SHARED ${PLUGIN_SOURCES})

    configure_toolchain(${name})
    configure_plugin(${name})

    target_link_libraries(${name} PRIVATE DialUpFramework::DialUpFramework)

    set(resolved_includes "")
    foreach(inc ${PLUGIN_INCLUDES})
        list(APPEND resolved_includes $<BUILD_INTERFACE:${inc}>)
    endforeach()

    list(REMOVE_DUPLICATES resolved_includes)

    target_include_directories(${name}
            PUBLIC
            ${resolved_includes}
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:include>
    )
endfunction()

function(dialup_import_plugin name)
    find_package(${name} REQUIRED)

    # If the target exists but doesn't have the proper properties, set them
    if(TARGET ${name} AND NOT TARGET ${name}::${name})
        add_library(${name}::${name} ALIAS ${name})
    endif()

    # If the imported target exists but doesn't have proper properties
    if(TARGET ${name}::${name})
        get_target_property(is_imported ${name}::${name} IMPORTED)
        if(is_imported)
            get_target_property(imported_location ${name}::${name} IMPORTED_LOCATION)
            get_target_property(imported_implib ${name}::${name} IMPORTED_IMPLIB)

            if(NOT imported_location)
                set_target_properties(${name}::${name} PROPERTIES
                    IMPORTED_LOCATION "${${name}_DIR}/bin/${name}.dll"
                )
            endif()

            if(NOT imported_implib)
                set_target_properties(${name}::${name} PROPERTIES
                    IMPORTED_IMPLIB "${${name}_DIR}/bin/${name}.lib"
                )
            endif()
        endif()
    endif()

endfunction()

function(test_library_linking target lib)
  get_target_property(lib_type ${lib} TYPE)
  message(STATUS "Library ${lib} type: ${lib_type}")

  if(TARGET ${lib})
    message(STATUS "Library ${lib} is a target")
    get_target_property(lib_location ${lib} LOCATION)
    message(STATUS "Library ${lib} location: ${lib_location}")
    get_target_property(lib_imported ${lib} IMPORTED)
    message(STATUS "Library ${lib} imported: ${lib_imported}")
    if(lib_imported)
      get_target_property(lib_implib ${lib} IMPORTED_IMPLIB)
      message(STATUS "Library ${lib} import library: ${lib_implib}")
    endif()
  else()
    message(STATUS "Library ${lib} is not a target")
  endif()
endfunction()

function(configure_imported_implib_fix target_name)
    get_target_property(configs ${target_name} IMPORTED_CONFIGURATIONS)
    foreach(config ${configs})
        string(TOUPPER "${config}" config_upper)

        get_target_property(lib ${target_name} IMPORTED_IMPLIB_${config_upper})
        if(lib)
            set_target_properties(${target_name} PROPERTIES IMPORTED_IMPLIB "${lib}")
            message(STATUS "Set IMPORTED_IMPLIB for ${target_name} to: ${lib}")
            break()
        endif()
    endforeach()
endfunction()
