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
KNOWROB_CONNECTOR_DIR=$PWD/knowrob_connector
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
    PATH=/usr/bin

    REDLAND_INSTALL_DIR=$BUILD_DIR/redland
    PATH="$REDLAND_INSTALL_DIR"/bin:$PATH
    LD_LIBRARY_PATH="$REDLAND_INSTALL_DIR"/lib
    LDFLAGS=-L"$LD_LIBRARY_PATH"
    PKG_CONFIG_PATH="$REDLAND_INSTALL_DIR"/lib/pkgconfig
    if [ ! -d "$REDLAND_INSTALL_DIR" ]; then
        set -e  # Exit immediately if a command fails
        set -o pipefail

        # Create a working directory
        REDLAND_SRC_DIR=$EXT_DIR/redland
        mkdir -p "$REDLAND_SRC_DIR"
        mkdir -p "$REDLAND_INSTALL_DIR"
        cd "$REDLAND_SRC_DIR" || exit

        echo "🔍 Preparing to build the following dependencies required for Redland:"
        echo "1. Raptor2"
        echo "2. Rasqal"
        echo "3. Bison"
        echo "4. Flex"
        echo "5. Gawk"
        echo "6. Gperf"
        echo "7. Virtuoso"

        # ==============================
        # 1. Build and Install Raptor2
        # ==============================
        echo "📦 Building Raptor2..."
        wget -c http://download.librdf.org/source/raptor2-2.0.15.tar.gz
        tar xf raptor2-2.0.15.tar.gz
        cd raptor2-2.0.15
        ./configure --prefix="$REDLAND_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC"
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
        ./configure --with-raptor2="$REDLAND_INSTALL_DIR" --prefix="$REDLAND_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC" PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 3. Build and Install bison
        # ==============================
        echo "📦 Building bison..."
        wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
        tar xf bison-3.8.2.tar.gz
        cd bison-3.8.2
        ./configure --prefix="$REDLAND_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 4. Build and Install flex
        # ==============================
        echo "📦 Building flex..."
        wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
        tar xf flex-2.6.4.tar.gz
        cd flex-2.6.4
        ./configure --prefix="$REDLAND_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 5. Build and Install gawk
        # ==============================
        echo "📦 Building gawk..."
        wget https://ftp.gnu.org/gnu/gawk/gawk-5.2.2.tar.gz
        tar xf gawk-5.2.2.tar.gz
        cd gawk-5.2.2
        ./configure --prefix="$REDLAND_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 6. Build and Install gperf
        # ==============================
        echo "📦 Building gperf..."
        wget https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz
        tar xf gperf-3.1.tar.gz
        cd gperf-3.1
        ./configure --prefix="$REDLAND_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 7. Build and Install Virtuoso
        # ==============================
        echo "📦 Building Virtuoso..."
        wget -c https://github.com/openlink/virtuoso-opensource/archive/refs/tags/v7.2.14.tar.gz
        tar xf v7.2.14.tar.gz
        cd virtuoso-opensource-7.2.14
        ./autogen.sh
        ./configure --prefix="$REDLAND_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 8. Build and Install Redland
        # ==============================
        echo "📦 Building Redland..."
        wget -c http://download.librdf.org/source/redland-1.0.17.tar.gz
        tar xf redland-1.0.17.tar.gz
        cd redland-1.0.17

        # Fix MySQL 'my_bool' compatibility issue
        echo "🛠️  Fixing MySQL 'my_bool' issue..."
        sed -i 's/\bmy_bool\b/bool/g' src/rdf_storage_mysql.c

        # Configure, build, and install
        ./configure --with-raptor2="$REDLAND_INSTALL_DIR" --with-rasqal="$REDLAND_INSTALL_DIR" --with-virtuoso="$REDLAND_INSTALL_DIR" --prefix="$REDLAND_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC" PKG_CONFIG_PATH="$PKG_CONFIG_PATH" LDFLAGS="$LDFLAGS"
        make -j$(nproc)
        make install

        echo "✅ All redland components built and installed successfully!"
    fi

    SWIPL_INSTALL_DIR=$BUILD_DIR/swipl
    JAVA_HOME="$SWIPL_INSTALL_DIR"/openjdk11
    PATH="$JAVA_HOME"/bin:$PATH
    LD_LIBRARY_PATH="$SWIPL_INSTALL_DIR/lib:$SWIPL_INSTALL_DIR/lib/swipl/lib/x86_64-linux:$LD_LIBRARY_PATH"
    if [ ! -d "$SWIPL_INSTALL_DIR" ]; then
        set -e  # Exit immediately if a command fails
        set -o pipefail

        # Create a working directory
        SWIPL_SRC_DIR=$EXT_DIR/swipl
        SWIPL_BUILD_DIR=$SWIPL_SRC_DIR/build
        SWIPL_DEPS_INSTALL_DIR=$BUILD_DIR/swipl_deps
        mkdir -p "$SWIPL_BUILD_DIR"
        mkdir -p "$SWIPL_DEPS_INSTALL_DIR"
        cd "$SWIPL_SRC_DIR" || exit

        echo "🔍 Preparing to build the following dependencies required for Redland:"
        echo "1. gperftools (libtcmalloc)"
        echo "2. libuuid (from util-linux)"
        echo "3. liblzma (xz)"
        echo "4. libarchive"
        echo "5. Berkeley DB"
        echo "6. OpenJDK 11"
        echo "7. JUnit 4"

        # ==============================
        # 1. Build and Install gperftools (libtcmalloc)
        # ==============================
        echo "📦 Building gperftools (libtcmalloc)..."
        wget -c https://github.com/gperftools/gperftools/releases/download/gperftools-2.12/gperftools-2.12.tar.gz
        tar xf gperftools-2.12.tar.gz
        cd gperftools-2.12
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 2. Build and Install LibUUID
        # ==============================
        # echo "📦 Building libuuid (from util-linux)..."
        wget https://www.mirrorservice.org/sites/ftp.ossp.org/pkg/lib/uuid/uuid-1.6.2.tar.gz
        tar xf uuid-1.6.2.tar.gz
        cd uuid-1.6.2
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" CFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 3. Build and Install liblzma (xz)
        # ==============================
        echo "📦 Building liblzma (xz)..."
        wget -c https://tukaani.org/xz/xz-5.4.5.tar.gz
        tar xf xz-5.4.5.tar.gz
        cd xz-5.4.5
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --disable-xz --disable-xzdec --disable-lzmadec CFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 3. Build and Install LibArchive
        # ==============================
        echo "📦 Building libarchive..."
        wget -c https://www.libarchive.org/downloads/libarchive-3.7.2.tar.xz
        tar xf libarchive-3.7.2.tar.xz
        cd libarchive-3.7.2
        ./configure --with-lzma="$SWIPL_DEPS_INSTALL_DIR" --prefix="$SWIPL_DEPS_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ..

        # ==============================
        # 4. Build and Install Berkeley DB
        # ==============================
        echo "📦 Building Berkeley DB..."
        wget -c http://download.oracle.com/berkeley-db/db-5.3.28.tar.gz
        tar xf db-5.3.28.tar.gz
        cd db-5.3.28/build_unix
        ../dist/configure --prefix="$SWIPL_DEPS_INSTALL_DIR" CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd ../..

        # ==============================
        # 5. Setup OpenJDK 11
        # ==============================
        echo "📦 Installing OpenJDK 11..."
        JDK_VERSION="11.0.22"
        JDK_BUILD="7"
        JDK_SHORT="jdk-11.0.22+7"
        JDK_ARCHIVE="OpenJDK11U-jdk_x64_linux_hotspot_${JDK_VERSION}_${JDK_BUILD}.tar.gz"
        JDK_URL="https://github.com/adoptium/temurin11-binaries/releases/download/jdk-${JDK_VERSION}+${JDK_BUILD}/${JDK_ARCHIVE}"
        JDK_DIR="$SWIPL_DEPS_INSTALL_DIR/openjdk11"

        wget -c "$JDK_URL"
        tar -xf "$JDK_ARCHIVE"
        mkdir -p "$JDK_DIR"
        mv "$JDK_SHORT"/* "$JDK_DIR"

        # ==============================
        # 6. Install JUnit 4
        # ==============================
        echo "📦 Installing JUnit 4..."
        JUNIT_DIR="$SWIPL_DEPS_INSTALL_DIR/junit"
        mkdir -p "$JUNIT_DIR"
        wget -c https://search.maven.org/remotecontent?filepath=junit/junit/4.13.2/junit-4.13.2.jar -O "$JUNIT_DIR/junit4.jar"

        # ==============================
        # 7. Build and Install SWI-Prolog
        # ==============================
        echo "📦 Building SWI-Prolog..."

        git clone https://github.com/SWI-Prolog/swipl-devel.git --depth 1 --recursive "$SWIPL_SRC_DIR/swipl-devel"
        sed -i '/#ifdef FILTER_LZOP/,/#endif/ s/FILTER_LZMA/FILTER_LZOP/g' "$SWIPL_SRC_DIR/swipl-devel/packages/archive/archive4pl.c"
        mkdir -p "$SWIPL_INSTALL_DIR"
        cmake -S "$SWIPL_SRC_DIR"/swipl-devel -B "$SWIPL_BUILD_DIR" -G Ninja \
            -DCMAKE_INSTALL_PREFIX="$SWIPL_INSTALL_DIR" \
            -DSWIPL_SHARED_LIB=OFF \
            -DCMAKE_BUILD_TYPE=PGO \
            -DCMAKE_EXE_LINKER_FLAGS="-L$SWIPL_DEPS_INSTALL_DIR/lib $SWIPL_DEPS_INSTALL_DIR/lib/libtcmalloc.a -lm" \
            -DLIBTCMALLOC_LIBRARY="" \
            -DLIBUUID_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
            -DLibArchive_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
            -DLibArchive_LIBRARY="$SWIPL_DEPS_INSTALL_DIR"/lib/libarchive.a \
            -DBDB_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
            -DBDB_LIBRARY="$SWIPL_DEPS_INSTALL_DIR"/lib/libdb.a \
            -DJAVA_HOME="$JAVA_HOME" \
            -DJUNIT_JAR="$JUNIT_DIR"/junit4.jar
        ninja -C "$SWIPL_BUILD_DIR"
        ninja install -C "$SWIPL_BUILD_DIR"
    fi

    PATH=$CMAKE_DIR/bin:$PATH LD_LIBRARY_PATH="$LD_LIBRARY_PATH" PKG_CONFIG_PATH="$REDLAND_INSTALL_DIR/lib/pkgconfig" "$KNOWROB_CONNECTOR_DIR"/build_knowrob_connector.sh
fi

end_time=$(date +%s)
elapsed=$(( end_time - start_time ))

echo "Build completed in $elapsed seconds"