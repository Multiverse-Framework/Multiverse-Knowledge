#!/bin/bash

MULTIVERSE_DIR="$PWD/../../.."
CMAKE_EXECUTABLE=$MULTIVERSE_DIR/build/CMake/bin/cmake
if [ ! -f "$CMAKE_EXECUTABLE" ]; then
    CMAKE_EXECUTABLE=$(which cmake)
fi
if [ ! -f "$CMAKE_EXECUTABLE" ]; then
    echo "cmake does not exist."
    exit 1
fi

echo "Building KnowRob Connector using CMake: $CMAKE_EXECUTABLE"
$CMAKE_EXECUTABLE -S $PWD -B build -DCMAKE_INSTALL_PREFIX:PATH=$PWD
make -C build
$CMAKE_EXECUTABLE --install build

echo "Copying shared library to lib"
cp build/libknowrob_connector.so lib/
