function(tidy target_name)
    find_program(
        CLANG_TIDY_EXE
        NAMES
        clang-tidy
        NO_CACHE
    )

    if(CLANG_TIDY_EXE)
        # Generate a files list without using command line paths
        set(FILES_LIST "${CMAKE_BINARY_DIR}/files_to_analyze.txt")
        file(WRITE ${FILES_LIST} "")

        # Add each source file on its own line
        foreach(SRC_FILE ${SRC_SOURCES})
            file(APPEND ${FILES_LIST} "${SRC_FILE}\n")
        endforeach()

        # Find header files and add them
        file(GLOB_RECURSE HEADER_FILES
                "${CMAKE_SOURCE_DIR}/src/include/*.h"
                "${CMAKE_SOURCE_DIR}/src/include/*.hpp"
        )
        foreach(HEADER_FILE ${HEADER_FILES})
            file(APPEND ${FILES_LIST} "${SRC_FILE}\n")
        endforeach()

        # Create a small wrapper script that CMake will call
        set(WRAPPER_SCRIPT "${CMAKE_BINARY_DIR}/run_clang_tidy_wrapper.cmake")
        file(WRITE ${WRAPPER_SCRIPT} "
        # CMake script to run clang-tidy without shell quoting issues
        file(STRINGS \"${FILES_LIST}\" ALL_FILES)

        # Debug information to verify paths
        message(STATUS \"Looking for compilation database at: ${CMAKE_BINARY_DIR}/compile_commands.json\")
        if(EXISTS \"${CMAKE_BINARY_DIR}/compile_commands.json\")
            message(STATUS \"Compilation database found\")
        else()
            message(STATUS \"Compilation database NOT found\")
        endif()

        foreach(FILE \${ALL_FILES})
            message(STATUS \"Running clang-tidy on: \${FILE}\")
            execute_process(
                COMMAND \"${CLANG_TIDY_EXE}\"
                        -p \"${CMAKE_BINARY_DIR}\"
                        --checks=modernize-*,performance-*,bugprone-*
                        --header-filter=\"^.*src.*$\"
                        \"\${FILE}\"
                RESULT_VARIABLE RESULT
            )

            if(NOT RESULT EQUAL 0)
                message(STATUS \"clang-tidy returned: \${RESULT} for \${FILE}\")
            endif()
        endforeach()
        ")

        # Add custom command to run the script before building
        add_custom_target(run_clang_tidy
                COMMAND ${CMAKE_COMMAND} -P "${WRAPPER_SCRIPT}"
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                COMMENT "Running clang-tidy analysis"
                VERBATIM
        )

        #add_dependencies(${PROJECT_NAME} run_clang_tidy)

    endif()
endfunction()