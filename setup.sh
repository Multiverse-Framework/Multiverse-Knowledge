#!/bin/bash

start_time=$(date +%s)

CURRENT_DIR=$PWD
cd $(dirname $0)

EXT_DIR=$PWD/ext
CMAKE_DIR=$EXT_DIR/CMake
USD_SRC_DIR=$EXT_DIR/OpenUSD
if [ ! -d "$CMAKE_DIR" ]; then
    mkdir -p $CMAKE_DIR
    CMAKE_TAR_FILE=cmake-4.0.1-linux-x86_64.tar.gz
    curl -L -o $EXT_DIR/$CMAKE_TAR_FILE https://github.com/Kitware/CMake/releases/download/v4.0.1/$CMAKE_TAR_FILE
    tar xf $EXT_DIR/$CMAKE_TAR_FILE -C $CMAKE_DIR --strip-components=1
    rm -f $EXT_DIR/$CMAKE_TAR_FILE

    git clone https://github.com/PixarAnimationStudios/OpenUSD.git --depth 1 --branch v25.02 $USD_SRC_DIR
fi
CMAKE_EXECUTABLE=$CMAKE_DIR/bin/cmake

BUILD_DIR=$PWD/build
USD_BUILD_DIR=$BUILD_DIR/USD
if [ -d "$USD_BUILD_DIR" ]; then
    mkdir -p $USD_BUILD_DIR
    PATH=$CMAKE_DIR/bin:$PATH python3 $EXT_DIR/OpenUSD/build_scripts/build_usd.py $USD_BUILD_DIR
fi

USD_SRC_DIR=$USD_SRC_DIR USD_BUILD_DIR=$USD_BUILD_DIR ./install.sh