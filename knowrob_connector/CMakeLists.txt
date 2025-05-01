cmake_minimum_required(VERSION 3.10.0)

project(KnowRobConnector)

set(KNOWROB_CONNECTOR knowrob_connector)
set(CMAKE_CXX_STANDARD 17)

set(Python3_EXECUTABLE "python3" CACHE STRING "Path to the Python executable")

function(build_knowrob_connector)
    add_library(${KNOWROB_CONNECTOR} SHARED ${CMAKE_CURRENT_SOURCE_DIR}/src/knowrob_connector.cpp)
    target_include_directories(${KNOWROB_CONNECTOR} PRIVATE 
        ${CMAKE_CURRENT_SOURCE_DIR}/multiverse_client/include
        ${CMAKE_CURRENT_SOURCE_DIR}/knowrob/include
    )
    target_link_directories(${KNOWROB_CONNECTOR} PRIVATE 
        ${CMAKE_CURRENT_SOURCE_DIR}/multiverse_client/include
        ${CMAKE_CURRENT_SOURCE_DIR}/knowrob/include
    )

    if(UNIX)
        # Find the installed Python interpreter
        find_package(Python3 REQUIRED COMPONENTS Interpreter)

        execute_process(
            COMMAND ${Python3_EXECUTABLE}-config --extension-suffix
            OUTPUT_VARIABLE PYTHON3_SUFFIX
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # Construct the library filename
        string(REPLACE ".so" "" PYTHON3_SUFFIX_BASE "${PYTHON3_SUFFIX}")
        message(STATUS "Build with KnowRob with suffix ${PYTHON3_SUFFIX_BASE}")
        set(KNOWROB_PYTHON_LIB "knowrob${PYTHON3_SUFFIX_BASE}")

        target_link_directories(${KNOWROB_CONNECTOR} PRIVATE 
            ${CMAKE_CURRENT_SOURCE_DIR}/lib
        )
        target_link_libraries(${KNOWROB_CONNECTOR} PRIVATE 
            multiverse_client_json
            ${KNOWROB_PYTHON_LIB}
        )
        install(TARGETS ${KNOWROB_CONNECTOR} DESTINATION 
            ${CMAKE_CURRENT_SOURCE_DIR}/lib
        )
    elseif(WIN32)
        # target_link_libraries(${MULTIVERSE_CLIENT_JSON} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/lib/libmultiverse_client_json.dll)
        # install(TARGETS ${MULTIVERSE_CLIENT_JSON} DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/lib)
    endif()
endfunction()

build_knowrob_connector()