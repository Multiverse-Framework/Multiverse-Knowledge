cmake_minimum_required(VERSION 3.10.0)

project(KnowRobConnector)

set(KNOWROB_CONNECTOR knowrob_connector)
set(CMAKE_CXX_STANDARD 17)

# Construct Boost Python component name based on Python version
set(Boost_Python_VERSION "python${Python_VERSION_MAJOR}${Python_VERSION_MINOR}")
set(Boost_Python_COMPONENT "Boost::${Boost_Python_VERSION}")
message(STATUS "Using Boost Python component: ${Boost_Python_COMPONENT}")

# Set Boost configurations
set(Boost_USE_STATIC_LIBS OFF)  # Use shared libraries by default
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_RUNTIME OFF)

# Find Boost and Boost.Python
find_package(Boost 1.50 REQUIRED COMPONENTS program_options serialization ${Boost_Python_VERSION})
if(NOT Boost_FOUND)
    message(FATAL_ERROR "Boost not found!")
endif()

# Explicitly set Boost.Python library path if necessary
set(Boost_PYTHON_LIBRARY /usr/lib/x86_64-linux-gnu/libboost_python38.so)
message(STATUS "Boost Python Library: ${Boost_PYTHON_LIBRARY}")

INCLUDE(FindPkgConfig)

pkg_check_modules(SWIPL REQUIRED swipl)
pkg_check_modules(MONGOC REQUIRED libmongoc-1.0)
pkg_check_modules(RAPTOR REQUIRED raptor2)
pkg_check_modules(REDLAND REQUIRED redland)
find_package(Python COMPONENTS Interpreter Development)
find_package(spdlog REQUIRED)

set(KNOWROB_LIBRARIES
  ${SWIPL_LIBRARIES}
  ${MONGOC_LIBRARIES}
  ${RAPTOR_LIBRARIES}
  ${REDLAND_LIBRARIES}
  ${Python_LIBRARIES}
  spdlog::spdlog)

function(build_knowrob_connector)
    add_library(${KNOWROB_CONNECTOR} SHARED ${CMAKE_CURRENT_SOURCE_DIR}/src/knowrob_connector.cpp)

    target_include_directories(${KNOWROB_CONNECTOR} PRIVATE 
        ${CMAKE_CURRENT_SOURCE_DIR}/multiverse_client/include
        ${CMAKE_CURRENT_SOURCE_DIR}/knowrob/include
        ${CMAKE_CURRENT_SOURCE_DIR}/knowrob/src/integration/python
        ${SWIPL_INCLUDE_DIRS}
        ${MONGOC_INCLUDE_DIRS}
        ${RAPTOR_INCLUDE_DIRS}
        ${REDLAND_INCLUDE_DIRS}
        ${Python_INCLUDE_DIRS}
        ${EIGEN3_INCLUDE_DIR}
        ${Boost_INCLUDE_DIRS})

    if (UNIX)
        target_link_libraries(${KNOWROB_CONNECTOR} PRIVATE 
            ${CMAKE_CURRENT_SOURCE_DIR}/lib/libmultiverse_client_json.so
            ${CMAKE_CURRENT_SOURCE_DIR}/lib/libknowrob.so
            ${Boost_LIBRARIES}  # Ensure all Boost libraries are linked
            ${Boost_PYTHON_LIBRARY})  # Explicitly link Boost.Python

        install(TARGETS ${KNOWROB_CONNECTOR} DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/lib)
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libknowrob_connector.so DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/lib RENAME knowrob.so)
    elseif (WIN32)
        # Windows-specific linking (if needed)
    endif()
endfunction()

build_knowrob_connector()