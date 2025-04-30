#!/bin/bash

start_time=$(date +%s)

cd "$(dirname "$0")" || exit

# Default value
USD_ENABLED=false
KNOWROB_CONNECTOR_ENABLED=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --usd)
            USD_ENABLED=true
            shift
        ;;
        --knowrob_connector)
            KNOWROB_CONNECTOR_ENABLED=true
            shift
        ;;
        *)
            echo "Unknown option: $1"
            exit 1
        ;;
    esac
done

EXT_DIR=$PWD/ext
BUILD_DIR=$PWD/build
CMAKE_DIR=$EXT_DIR/CMake
if [ "$USD_ENABLED" = true ] || [ "$KNOWROB_CONNECTOR_ENABLED" = true ]; then
    if [ ! -d "$CMAKE_DIR" ]; then
        mkdir -p "$CMAKE_DIR"
        CMAKE_TAR_FILE=cmake-4.0.1-linux-x86_64.tar.gz
        curl -L -o "$EXT_DIR"/$CMAKE_TAR_FILE https://github.com/Kitware/CMake/releases/download/v4.0.1/$CMAKE_TAR_FILE
        tar xf "$EXT_DIR"/$CMAKE_TAR_FILE -C "$CMAKE_DIR" --strip-components=1
        rm -f "$EXT_DIR"/$CMAKE_TAR_FILE
    fi
fi

if [ "$USD_ENABLED" = true ]; then
    USD_SRC_DIR=$EXT_DIR/OpenUSD
    git clone https://github.com/PixarAnimationStudios/OpenUSD.git --depth 1 --branch v25.02 "$USD_SRC_DIR"
    
    USD_BUILD_DIR=$BUILD_DIR/USD
    if [ ! -d "$USD_BUILD_DIR" ]; then
        PYTHON_EXECUTABLE=python3
        mkdir -p "$USD_BUILD_DIR"
        $PYTHON_EXECUTABLE "$USD_SRC_DIR"/build_scripts/build_usd.py "$USD_BUILD_DIR" \
        --no-tests \
        --no-examples \
        --no-tutorials \
        --no-tools \
        --no-docs \
        --no-python-docs \
        --python \
        --prefer-speed-over-safety \
        --no-debug-python \
        --no-imaging \
        --no-ptex \
        --no-openvdb \
        --no-usdview \
        --no-embree \
        --no-openimageio \
        --no-opencolorio \
        --no-alembic \
        --no-hdf5 \
        --no-draco \
        --no-materialx \
        --no-onetbb \
        --no-usdValidation \
        --no-mayapy-tests \
        --no-animx-tests

        PATH=$CMAKE_DIR/bin:$PATH USD_SRC_DIR=$USD_SRC_DIR USD_BUILD_DIR=$USD_BUILD_DIR PYTHON_EXECUTABLE=$PYTHON_EXECUTABLE ./install.sh

        USD_BIN_DIR=$PWD/USD/linux
        if [ ! -d "$USD_BIN_DIR" ]; then
            mkdir -p "$USD_BIN_DIR/lib/"
            mkdir -p "$USD_BIN_DIR/plugin/"
        fi
        cp -rf "$USD_BUILD_DIR"/lib/* "$USD_BIN_DIR"/lib/
        cp -rf "$USD_BUILD_DIR"/plugin/* "$USD_BIN_DIR"/plugin/
    fi
fi

if [ "$KNOWROB_CONNECTOR_ENABLED" = true ]; then
    REDLAND_INSTALL_DIR=$BUILD_DIR/redland
    PATH="/usr/bin"
    LD_LIBRARY_PATH="$REDLAND_INSTALL_DIR"/lib
    if [ ! -d "$REDLAND_INSTALL_DIR" ]; then
        set -e  # Exit immediately if a command fails
        set -o pipefail

        echo "🔍 Preparing to build Raptor2, Rasqal, and Redland from source."

        # Install dependencies manually if missing:
        # Uncomment the following line if you don't already have the required packages.
        #
        # sudo apt-get update
        # sudo apt-get install -y \
        #     build-essential     # Compiler tools: gcc, g++, make
        #     autoconf automake libtool # Autotools for generating build scripts
        #     flex bison           # For generating parsers (needed by Rasqal)
        #     pkg-config           # Helper for managing compiler/linker flags
        #     libxml2-dev          # XML parsing library (needed by Raptor2)
        #     libpcre3-dev         # Regex support (needed by Rasqal)
        #     uuid-dev             # UUID library (used by Redland)
        #     libmysqlclient-dev   # MySQL client libraries (optional for MySQL backend)
        #     wget                 # Tool to download source tarballs

        # Create a working directory
        REDLAND_SRC_DIR=$EXT_DIR/redland
        mkdir -p "$REDLAND_SRC_DIR"
        mkdir -p "$REDLAND_INSTALL_DIR"
        cd "$REDLAND_SRC_DIR" || exit

        # ==============================
        # 1. Build and Install Raptor2
        # ==============================
        echo "📦 Building Raptor2..."
        wget -c http://download.librdf.org/source/raptor2-2.0.15.tar.gz
        tar xf raptor2-2.0.15.tar.gz
        cd raptor2-2.0.15
        make clean
        ./configure --with-openssl --prefix="$REDLAND_INSTALL_DIR"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 2. Build and Install Rasqal
        # ==============================
        echo "📦 Building Rasqal..."
        wget -c http://download.librdf.org/source/rasqal-0.9.33.tar.gz
        tar xf rasqal-0.9.33.tar.gz
        cd rasqal-0.9.33
        make clean
        ./configure --with-raptor2="$REDLAND_INSTALL_DIR" --prefix="$REDLAND_INSTALL_DIR"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 3. Build and Install Redland
        # ==============================
        echo "📦 Building Redland..."
        wget -c http://download.librdf.org/source/redland-1.0.17.tar.gz
        tar xf redland-1.0.17.tar.gz
        cd redland-1.0.17

        # Fix MySQL 'my_bool' compatibility issue
        echo "🛠️  Fixing MySQL 'my_bool' issue..."
        sed -i 's/\bmy_bool\b/bool/g' src/rdf_storage_mysql.c

        # Configure, build, and install
        make clean
        ./configure --with-raptor2="$REDLAND_INSTALL_DIR" --with-rasqal="$REDLAND_INSTALL_DIR" --prefix="$REDLAND_INSTALL_DIR"
        make -j$(nproc)
        make install

        echo "✅ All redland components built and installed successfully!"
    fi

    PATH=$CMAKE_DIR/bin:$PATH LD_LIBRARY_PATH="$LD_LIBRARY_PATH" PKG_CONFIG_PATH="$REDLAND_INSTALL_DIR/lib/pkgconfig" ./knowrob_connector/build_knowrob_connector.sh
fi

end_time=$(date +%s)
elapsed=$(( end_time - start_time ))

echo "Build completed in $elapsed seconds"