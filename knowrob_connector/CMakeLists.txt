cmake_minimum_required(VERSION 3.10.0)

project(KnowRobConnector)

set(KNOWROB_CONNECTOR knowrob_connector)
set(CMAKE_CXX_STANDARD 17)

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
        target_link_libraries(${KNOWROB_CONNECTOR} PRIVATE 
            ${CMAKE_CURRENT_SOURCE_DIR}/lib/libmultiverse_client_json.so
            ${CMAKE_CURRENT_SOURCE_DIR}/lib/libknowrob.so
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
