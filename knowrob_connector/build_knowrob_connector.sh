#!/bin/bash

cd "$(dirname "$0")" || exit
MULTIVERSE_KNOWLEDGE_DIR="$PWD/.."
CMAKE_EXECUTABLE=$MULTIVERSE_KNOWLEDGE_DIR/ext/CMake/bin/cmake
if [ ! -f "$CMAKE_EXECUTABLE" ]; then
    CMAKE_EXECUTABLE=$(which cmake)
fi
if [ ! -f "$CMAKE_EXECUTABLE" ]; then
    echo "cmake does not exist."
    exit 1
fi

if [ -z "$PYTHON_EXECUTABLE" ]; then
    PYTHON_EXECUTABLE=$(which python3)
fi

KNOWROB_BUILD_DIR="$PWD"/build/knowrob
if [ ! -d "$KNOWROB_BUILD_DIR" ]; then
    echo "Building KnowRob using CMake: $CMAKE_EXECUTABLE"
    echo "PATH: $PATH"
    echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
    echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
    echo "PYTHON_EXECUTABLE: $PYTHON_EXECUTABLE"

    KNOWROB_SRC_DIR="$PWD"/knowrob
    mkdir -p "$KNOWROB_BUILD_DIR"

    $CMAKE_EXECUTABLE -S "$KNOWROB_SRC_DIR" -B "$KNOWROB_BUILD_DIR" \
        -DCATKIN=OFF \
        -DPYTHON_MODULE_LIBDIR="dist-packages" \
        -DPython3_EXECUTABLE="$PYTHON_EXECUTABLE" \
        -DKNOWROB_USE_SUFFIX=ON
    make -C "$KNOWROB_BUILD_DIR" -j 4
fi

PYTHON_SUFFIX=$("$PYTHON_EXECUTABLE"-config --extension-suffix)
cp -f "$KNOWROB_BUILD_DIR"/knowrob_py.so "$PWD"/dist-packages/knowrob"$PYTHON_SUFFIX"
cp -f "$KNOWROB_BUILD_DIR"/libknowrob"$PYTHON_SUFFIX" "$PWD"/lib/libknowrob"$PYTHON_SUFFIX"

KNOWROB_CONNECTOR_BUILD_DIR="$PWD"/build/knowrob_connector
if [ ! -d "$KNOWROB_CONNECTOR_BUILD_DIR" ]; then
    KNOWROB_CONNECTOR_SRC_DIR=$PWD
    mkdir -p "$KNOWROB_CONNECTOR_BUILD_DIR"

    echo "Building KnowRob Connector using CMake: $CMAKE_EXECUTABLE"
    $CMAKE_EXECUTABLE -S "$KNOWROB_CONNECTOR_SRC_DIR" -B "$KNOWROB_CONNECTOR_BUILD_DIR" -DCMAKE_INSTALL_PREFIX:PATH="$KNOWROB_CONNECTOR_SRC_DIR" -DPython3_EXECUTABLE="$PYTHON_EXECUTABLE"
    make -C "$KNOWROB_CONNECTOR_BUILD_DIR" install -j 4
fi
