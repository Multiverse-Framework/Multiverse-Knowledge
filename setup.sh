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
INSTALL_DIR=$PWD/install
KNOWROB_CONNECTOR_DIR=$PWD/knowrob_connector
CMAKE_INSTALL_DIR=$INSTALL_DIR/CMake
CMAKE_EXECUTABLE=$CMAKE_INSTALL_DIR/bin/cmake
NINJA_INSTALL_DIR=$INSTALL_DIR/ninja
NINJA_EXECUTABLE=$NINJA_INSTALL_DIR/ninja
if [ "$USD_ENABLED" = true ] || [ "$KNOWROB_CONNECTOR_ENABLED" = true ]; then
    if [ ! -f "$CMAKE_EXECUTABLE" ]; then
        mkdir -p "$CMAKE_INSTALL_DIR"
        CMAKE_TAR_FILE=cmake-4.0.1-linux-x86_64.tar.gz
        curl -L -o "$EXT_DIR"/$CMAKE_TAR_FILE https://github.com/Kitware/CMake/releases/download/v4.0.1/$CMAKE_TAR_FILE
        tar xf "$EXT_DIR"/$CMAKE_TAR_FILE -C "$CMAKE_INSTALL_DIR" --strip-components=1
    fi
    
    if [ ! -f "$NINJA_EXECUTABLE" ]; then
        mkdir -p "$NINJA_INSTALL_DIR"
        wget https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-linux.zip -O "$EXT_DIR"/ninja-linux.zip
        unzip "$EXT_DIR"/ninja-linux.zip -d "$NINJA_INSTALL_DIR"
    fi
fi

if [ "$USD_ENABLED" = true ]; then
    USD_SRC_DIR=$EXT_DIR/OpenUSD
    git clone https://github.com/PixarAnimationStudios/OpenUSD.git --depth 1 --branch v25.02 "$USD_SRC_DIR"
    
    USD_INSTALL_DIR=$INSTALL_DIR/USD
    if [ ! -d "$USD_INSTALL_DIR" ]; then
        PYTHON_EXECUTABLE=python3
        mkdir -p "$USD_INSTALL_DIR"
        $PYTHON_EXECUTABLE "$USD_SRC_DIR"/build_scripts/build_usd.py "$USD_INSTALL_DIR" \
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
        
        PATH=$CMAKE_DIR/bin:$PATH USD_SRC_DIR=$USD_SRC_DIR USD_INSTALL_DIR=$USD_INSTALL_DIR PYTHON_EXECUTABLE=$PYTHON_EXECUTABLE ./install.sh
        
        USD_BIN_DIR=$PWD/USD/linux
        if [ ! -d "$USD_BIN_DIR" ]; then
            mkdir -p "$USD_BIN_DIR/lib/"
            mkdir -p "$USD_BIN_DIR/plugin/"
        fi
        cp -rf "$USD_INSTALL_DIR"/lib/* "$USD_BIN_DIR"/lib/
        cp -rf "$USD_INSTALL_DIR"/plugin/* "$USD_BIN_DIR"/plugin/
    fi
fi

if [ "$KNOWROB_CONNECTOR_ENABLED" = true ]; then
    PATH=$NINJA_INSTALL_DIR:/usr/bin
    
    REDLAND_INSTALL_DIR=$INSTALL_DIR/redland
    REDLAND_DEPS_INSTALL_DIR=$INSTALL_DIR/redland_deps
    PATH="$REDLAND_INSTALL_DIR"/bin:"$REDLAND_DEPS_INSTALL_DIR"/bin:$PATH
    LD_LIBRARY_PATH="$REDLAND_INSTALL_DIR"/lib:"$REDLAND_DEPS_INSTALL_DIR"/lib
    LDFLAGS="-L$REDLAND_INSTALL_DIR -L$REDLAND_DEPS_INSTALL_DIR"
    PKG_CONFIG_PATH="$REDLAND_INSTALL_DIR"/lib/pkgconfig:"$REDLAND_DEPS_INSTALL_DIR"/lib/pkgconfig:"$REDLAND_DEPS_INSTALL_DIR"/share/pkgconfig
    if [ ! -d "$REDLAND_INSTALL_DIR" ]; then
        set -e  # Exit immediately if a command fails
        set -o pipefail
        
        # Create a working directory
        REDLAND_SRC_DIR=$EXT_DIR/redland
        mkdir -p "$REDLAND_SRC_DIR"
        mkdir -p "$REDLAND_INSTALL_DIR"
        mkdir -p "$REDLAND_DEPS_INSTALL_DIR"
        cd "$REDLAND_SRC_DIR" || exit
        
        echo "🔍 Preparing to build the following dependencies required for Redland:"
        echo "1. liblzma (xz)"
        echo "2. libxml2"
        echo "3. yajl"
        echo "4. libxslt"
        echo "5. openssl"
        echo "6. cyrus-sasl"
        echo "7. OpenLDAP"
        echo "8. libcurl"
        echo "9. Raptor2"
        echo "10. libuuid (from util-linux)"
        echo "11. pcre1"
        echo "12. Rasqal"
        echo "13. bison"
        echo "14. flex"
        echo "15. gawk"
        echo "16. gperf"
        echo "17. Virtuoso"
        
        
        # ==============================
        # 1. Build and Install liblzma (xz)
        # ==============================
        echo "📦 Building liblzma (xz)..."
        wget -c https://github.com/tukaani-project/xz/releases/download/v5.8.1/xz-5.8.1.tar.gz -O xz-5.8.1.tar.gz
        tar xf xz-5.8.1.tar.gz
        cd xz-5.8.1
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 2. Build and Install libxml2
        # ==============================
        echo "📦 Building libxml2..."
        wget -c http://xmlsoft.org/sources/libxml2-2.9.12.tar.gz -O libxml2-2.9.12.tar.gz
        tar xf libxml2-2.9.12.tar.gz
        cd libxml2-2.9.12
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --with-python=no --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 3. Build and Install yajl
        # ==============================
        echo "📦 Building yajl..."
        wget -c https://github.com/lloyd/yajl/archive/refs/tags/2.1.0.tar.gz -O yajl-2.1.0.tar.gz
        tar xf yajl-2.1.0.tar.gz
        cd yajl-2.1.0
        mkdir -p build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX="$REDLAND_DEPS_INSTALL_DIR" -DYAJL_BUILD_STATIC_LIBS=ON
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 4. Build and Install libxslt
        # ==============================
        echo "📦 Building libxslt..."
        wget -c http://xmlsoft.org/sources/libxslt-1.1.34.tar.gz -O libxslt-1.1.34.tar.gz
        tar xf libxslt-1.1.34.tar.gz
        cd libxslt-1.1.34
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 5. Build and Install openssl
        # ==============================
        # Note: OpenSSL 1.1.1f is used for compatibility with Redland
        # OpenSSL 3.x may not be compatible with some libraries
        echo "📦 Building openssl..."
        wget -c https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1f/openssl-1.1.1f.tar.gz -O openssl-1.1.1f.tar.gz
        tar xf openssl-1.1.1f.tar.gz
        cd openssl-1.1.1f
        ./Configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --openssldir="$REDLAND_DEPS_INSTALL_DIR"/ssl no-shared linux-x86_64
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 6. Build and Install sasl
        # ==============================
        echo "📦 Building cyrus-sasl..."
        wget -c https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.28/cyrus-sasl-2.1.28.tar.gz -O cyrus-sasl-2.1.28.tar.gz
        tar xf cyrus-sasl-2.1.28.tar.gz
        cd cyrus-sasl-2.1.28
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-gssapi --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 7. Build and Install OpenLDAP
        # ==============================
        echo "📦 Building OpenLDAP..."
        wget -c https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.6.9.tgz -O openldap-2.6.9.tgz
        tar -xzf openldap-2.6.9.tgz
        cd openldap-2.6.9
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 8. Build and Install libcurl
        # ==============================
        echo "📦 Building libcurl..."
        wget -c https://curl.se/download/curl-8.13.0.tar.gz -O curl-8.13.0.tar.gz
        tar -xzf curl-8.13.0.tar.gz
        cd curl-8.13.0
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --without-libpsl --with-ssl="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 9. Build and Install Raptor2
        # ==============================
        echo "📦 Building Raptor2..."
        wget -c http://download.librdf.org/source/raptor2-2.0.16.tar.gz -O raptor2-2.0.16.tar.gz
        tar xf raptor2-2.0.16.tar.gz
        cd raptor2-2.0.16
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 10. Build and Install LibUUID
        # ==============================
        echo "📦 Building libuuid (from util-linux)..."
        wget -c https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.41/util-linux-2.41.tar.xz -O util-linux-2.41.tar.xz
        tar xf util-linux-2.41.tar.xz
        cd util-linux-2.41
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-all-programs --disable-nls --enable-libuuid -disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 11. Build and Install pcre1
        # ==============================
        echo "📦 Building and Install pcre1..."
        wget -c https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz/download -O pcre-8.45.tar.gz
        tar xf pcre-8.45.tar.gz
        cd pcre-8.45
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" -disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 12. Build and Install Rasqal
        # ==============================
        echo "📦 Building Rasqal..."
        wget -c http://download.librdf.org/source/rasqal-0.9.33.tar.gz -O rasqal-0.9.33.tar.gz
        tar xf rasqal-0.9.33.tar.gz
        cd rasqal-0.9.33
        ./configure --with-raptor2="$REDLAND_DEPS_INSTALL_DIR" --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC" PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 13. Build and Install bison
        # ==============================
        echo "📦 Building bison..."
        wget -c https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz -O bison-3.8.2.tar.gz
        tar xf bison-3.8.2.tar.gz
        cd bison-3.8.2
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 14. Build and Install flex
        # ==============================
        echo "📦 Building flex..."
        wget -c https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz -O flex-2.6.4.tar.gz
        tar xf flex-2.6.4.tar.gz
        cd flex-2.6.4
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 15. Build and Install gawk
        # ==============================
        echo "📦 Building gawk..."
        wget https://ftp.gnu.org/gnu/gawk/gawk-5.2.2.tar.gz -O gawk-5.2.2.tar.gz
        tar xf gawk-5.2.2.tar.gz
        cd gawk-5.2.2
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 16. Build and Install gperf
        # ==============================
        echo "📦 Building gperf..."
        wget https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz -O gperf-3.1.tar.gz
        tar xf gperf-3.1.tar.gz
        cd gperf-3.1
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 17. Build and Install Virtuoso
        # ==============================
        echo "📦 Building Virtuoso..."
        wget -c https://github.com/openlink/virtuoso-opensource/archive/refs/tags/v7.2.14.tar.gz -O v7.2.14.tar.gz
        tar xf v7.2.14.tar.gz
        cd virtuoso-opensource-7.2.14
        ./autogen.sh
        ./configure --prefix="$REDLAND_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$REDLAND_SRC_DIR"
        
        # ==============================
        # 18. Build and Install Redland
        # ==============================
        echo "📦 Building Redland..."
        wget -c http://download.librdf.org/source/redland-1.0.17.tar.gz -O redland-1.0.17.tar.gz
        tar xf redland-1.0.17.tar.gz
        cd redland-1.0.17
        
        # Fix MySQL 'my_bool' compatibility issue
        echo "🛠️  Fixing MySQL 'my_bool' issue..."
        sed -i 's/\bmy_bool\b/bool/g' src/rdf_storage_mysql.c
        
        # Configure, build, and install
        ./configure --with-raptor2="$REDLAND_DEPS_INSTALL_DIR" --with-curl="$REDLAND_DEPS_INSTALL_DIR" --with-rasqal="$REDLAND_DEPS_INSTALL_DIR" --with-virtuoso="$REDLAND_DEPS_INSTALL_DIR" --prefix="$REDLAND_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC" PKG_CONFIG_PATH="$PKG_CONFIG_PATH" LDFLAGS="$LDFLAGS"
        make -j$(nproc)
        make install
        
        echo "✅ All redland components built and installed successfully!"
    fi
    
    SWIPL_INSTALL_DIR=$INSTALL_DIR/swipl
    SWIPL_DEPS_INSTALL_DIR=$INSTALL_DIR/swipl_deps
    JAVA_HOME="$SWIPL_INSTALL_DIR"/openjdk11
    PATH="$JAVA_HOME"/bin:$PATH
    LD_LIBRARY_PATH="$SWIPL_INSTALL_DIR/lib/swipl/lib/x86_64-linux:$SWIPL_DEPS_INSTALL_DIR/lib:$LD_LIBRARY_PATH"
    LDFLAGS="-L$SWIPL_INSTALL_DIR/lib/swipl/lib/x86_64-linux -L$SWIPL_DEPS_INSTALL_DIR/lib $LDFLAGS"
    PKG_CONFIG_PATH="$SWIPL_INSTALL_DIR"/share/pkgconfig:"$SWIPL_DEPS_INSTALL_DIR"/lib/pkgconfig:"$PKG_CONFIG_PATH"
    if [ ! -d "$SWIPL_INSTALL_DIR" ]; then
        set -e  # Exit immediately if a command fails
        set -o pipefail
        
        # Create a working directory
        SWIPL_SRC_DIR=$EXT_DIR/swipl
        mkdir -p "$SWIPL_SRC_DIR"
        mkdir -p "$SWIPL_DEPS_INSTALL_DIR"
        cd "$SWIPL_SRC_DIR" || exit
        
        echo "🔍 Preparing to build the following dependencies required for SWI-Prolog:"
        echo "1. gperftools (libtcmalloc)"
        echo "2. libuuid (from util-linux)"
        echo "3. liblzma (xz)"
        echo "4. libarchive"
        echo "5. Berkeley DB"
        echo "6. OpenJDK 11"
        echo "7. JUnit 4"
        echo "8. GMP"
        echo "9. Readline"
        echo "10. libedit"
        echo "11. libtool"
        
        # ==============================
        # 1. Build and Install gperftools (libtcmalloc)
        # ==============================
        echo "📦 Building gperftools (libtcmalloc)..."
        wget -c https://github.com/gperftools/gperftools/releases/download/gperftools-2.16/gperftools-2.16.tar.gz -O gperftools-2.16.tar.gz
        tar xf gperftools-2.16.tar.gz
        cd gperftools-2.16
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$SWIPL_SRC_DIR"
        
        # ==============================
        # 2. Build and Install uuid
        # ==============================
        echo "📦 Building uuid (from OSSP)"
        wget -c https://www.mirrorservice.org/sites/ftp.ossp.org/pkg/lib/uuid/uuid-1.6.2.tar.gz -O uuid-1.6.2.tar.gz
        tar xf uuid-1.6.2.tar.gz
        cd uuid-1.6.2
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$SWIPL_SRC_DIR"
        
        # ==============================
        # 3. Build and Install liblzma (xz)
        # ==============================
        echo "📦 Building liblzma (xz)..."
        wget -c https://github.com/tukaani-project/xz/releases/download/v5.8.1/xz-5.8.1.tar.gz -O xz-5.8.1.tar.gz
        tar xf xz-5.8.1.tar.gz
        cd xz-5.8.1
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$SWIPL_SRC_DIR"
        
        # ==============================
        # 4. Build and Install LibArchive
        # ==============================
        echo "📦 Building libarchive..."
        wget -c https://www.libarchive.org/downloads/libarchive-3.7.9.tar.xz -O libarchive-3.7.9.tar.xz
        tar xf libarchive-3.7.9.tar.xz
        cd libarchive-3.7.9
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$SWIPL_SRC_DIR"
        
        # ==============================
        # 5. Build and Install Berkeley DB
        # ==============================
        echo "📦 Building Berkeley DB..."
        wget -c http://download.oracle.com/berkeley-db/db-5.3.28.tar.gz -O db-5.3.28.tar.gz
        tar xf db-5.3.28.tar.gz
        cd db-5.3.28/build_unix
        ../dist/configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$SWIPL_SRC_DIR"
        
        # ==============================
        # 6. Setup OpenJDK 11
        # ==============================
        echo "📦 Installing OpenJDK 11..."
        JDK_VERSION="11.0.22"
        JDK_BUILD="7"
        JDK_SHORT="jdk-11.0.22+7"
        JDK_ARCHIVE="OpenJDK11U-jdk_x64_linux_hotspot_${JDK_VERSION}_${JDK_BUILD}.tar.gz"
        JDK_URL="https://github.com/adoptium/temurin11-binaries/releases/download/jdk-${JDK_VERSION}+${JDK_BUILD}/${JDK_ARCHIVE}"
        JDK_DIR="$SWIPL_DEPS_INSTALL_DIR/openjdk11"
        
        wget -c "$JDK_URL" -O "$JDK_ARCHIVE"
        tar -xf "$JDK_ARCHIVE"
        mkdir -p "$JDK_DIR"
        mv "$JDK_SHORT"/* "$JDK_DIR"
        
        # ==============================
        # 7. Install JUnit 4
        # ==============================
        echo "📦 Installing JUnit 4..."
        JUNIT_DIR="$SWIPL_DEPS_INSTALL_DIR/junit"
        mkdir -p "$JUNIT_DIR"
        wget -c https://search.maven.org/remotecontent?filepath=junit/junit/4.13.2/junit-4.13.2.jar -O "$JUNIT_DIR/junit4.jar"
        
        # ==============================
        # 8. Build and Install GMP
        # ==============================
        wget -c https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz -O gmp-6.3.0.tar.xz
        tar xf gmp-6.3.0.tar.xz
        cd gmp-6.3.0
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --enable-assembly=no --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make clean
        make -j$(nproc)
        make install
        cd "$SWIPL_SRC_DIR"
        
        # ==============================
        # 9. Build and Install Readline
        # ==============================
        echo "📦 Building Readline..."
        wget -c https://ftp.gnu.org/gnu/readline/readline-8.2.13.tar.gz -O readline-8.2.13.tar.gz
        tar xf readline-8.2.13.tar.gz
        cd readline-8.2.13
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$SWIPL_SRC_DIR"
        
        # ==============================
        # 10. Build and Install libedit
        # ==============================
        echo "📦 Building libedit..."
        wget -c https://thrysoee.dk/editline/libedit-20250104-3.1.tar.gz -O libedit-20250104-3.1.tar.gz
        tar xf libedit-20250104-3.1.tar.gz
        cd libedit-20250104-3.1
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        cd "$SWIPL_SRC_DIR"
        
        # ==============================
        # 11. Build and Install libtool
        # ==============================
        echo "📦 Building libtool..."
        wget -c https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz -O libtool-2.5.4.tar.xz
        tar xf libtool-2.5.4.tar.xz
        cd libtool-2.5.4
        ./configure --prefix="$SWIPL_DEPS_INSTALL_DIR" --disable-shared --enable-static CFLAGS="-fPIC" CXXFLAGS="-fPIC"
        make -j$(nproc)
        make install
        
        # ==============================
        # 12. Build and Install SWI-Prolog
        # ==============================
        echo "📦 Building SWI-Prolog..."
        
        if [ ! -d "$SWIPL_SRC_DIR/swipl" ]; then
            git clone https://github.com/SWI-Prolog/swipl.git --branch V9.3.17 --depth 1 --recursive "$SWIPL_SRC_DIR/swipl"
        fi
        sed -i '/#ifdef FILTER_LZOP/,/#endif/ s/FILTER_LZMA/FILTER_LZOP/g' "$SWIPL_SRC_DIR/swipl/packages/archive/archive4pl.c"
        SWIPL_BUILD_DIR="$SWIPL_SRC_DIR"/build
        mkdir -p "$SWIPL_INSTALL_DIR"
        mkdir -p "$SWIPL_BUILD_DIR"
        # =============================== Build shared lib
        $CMAKE_EXECUTABLE -S "$SWIPL_SRC_DIR"/swipl -B "$SWIPL_BUILD_DIR" -G Ninja \
        -DCMAKE_INSTALL_PREFIX="$SWIPL_INSTALL_DIR" \
        -DSWIPL_SHARED_LIB=ON \
        -DCMAKE_BUILD_TYPE=PGO \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DCMAKE_C_COMPILER=gcc-11 \
        -DCMAKE_CXX_COMPILER=g++-11 \
        -DCMAKE_LINKER=g++-11 \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        -DCMAKE_INSTALL_RPATH="$SWIPL_INSTALL_DIR/lib" \
        -DCMAKE_EXE_LINKER_FLAGS="-L$SWIPL_DEPS_INSTALL_DIR/lib -lm -fuse-ld=gold -lstdc++" \
        -DLIBUUID_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DLibArchive_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DLibArchive_LIBRARY="$SWIPL_DEPS_INSTALL_DIR"/lib/libarchive.a \
        -DBDB_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DBDB_LIBRARY="$SWIPL_DEPS_INSTALL_DIR"/lib/libdb.a \
        -DGMP_LIBRARIES="$SWIPL_DEPS_INSTALL_DIR"/lib/libgmp.a \
        -DGMP_LIBRARIES_DIR="$SWIPL_DEPS_INSTALL_DIR"/lib \
        -DGMP_INCLUDE_DIRS="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DUSE_LIBBF=OFF \
        -DReadline_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DReadline_LIBRARY="$SWIPL_DEPS_INSTALL_DIR"/lib/libreadline.a \
        -DLIBEDIT_LIBRARIES="$SWIPL_DEPS_INSTALL_DIR"/lib/libedit.a \
        -DLIBEDIT_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DLTDL_LIBRARY="$SWIPL_DEPS_INSTALL_DIR/lib/libltdl.a" \
        -DLTDL_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR/include" \
        -DJAVA_HOME="$JAVA_HOME" \
        -DJUNIT_JAR="$JUNIT_DIR"/junit4.jar
        $NINJA_EXECUTABLE -C "$SWIPL_BUILD_DIR"
        $NINJA_EXECUTABLE install -C "$SWIPL_BUILD_DIR"
        # ============================== Build static lib
        $CMAKE_EXECUTABLE -S "$SWIPL_SRC_DIR"/swipl -B "$SWIPL_BUILD_DIR" -G Ninja \
        -DCMAKE_INSTALL_PREFIX="$SWIPL_INSTALL_DIR" \
        -DSWIPL_SHARED_LIB=OFF \
        -DCMAKE_BUILD_TYPE=PGO \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DCMAKE_C_COMPILER=gcc-11 \
        -DCMAKE_CXX_COMPILER=g++-11 \
        -DCMAKE_LINKER=g++-11 \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        -DCMAKE_INSTALL_RPATH="$SWIPL_INSTALL_DIR/lib" \
        -DCMAKE_EXE_LINKER_FLAGS="-L$SWIPL_DEPS_INSTALL_DIR/lib -lm -fuse-ld=gold -lstdc++" \
        -DLIBTCMALLOC_LIBRARY="$SWIPL_DEPS_INSTALL_DIR/lib/libtcmalloc.a" \
        -DLIBUUID_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DLibArchive_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DLibArchive_LIBRARY="$SWIPL_DEPS_INSTALL_DIR"/lib/libarchive.a \
        -DBDB_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DBDB_LIBRARY="$SWIPL_DEPS_INSTALL_DIR"/lib/libdb.a \
        -DGMP_LIBRARIES="$SWIPL_DEPS_INSTALL_DIR"/lib/libgmp.a \
        -DGMP_LIBRARIES_DIR="$SWIPL_DEPS_INSTALL_DIR"/lib \
        -DGMP_INCLUDE_DIRS="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DUSE_LIBBF=OFF \
        -DReadline_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DReadline_LIBRARY="$SWIPL_DEPS_INSTALL_DIR"/lib/libreadline.a \
        -DLIBEDIT_LIBRARIES="$SWIPL_DEPS_INSTALL_DIR"/lib/libedit.a \
        -DLIBEDIT_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR"/include \
        -DLTDL_LIBRARY="$SWIPL_DEPS_INSTALL_DIR/lib/libltdl.a" \
        -DLTDL_INCLUDE_DIR="$SWIPL_DEPS_INSTALL_DIR/include" \
        -DJAVA_HOME="$JAVA_HOME" \
        -DJUNIT_JAR="$JUNIT_DIR"/junit4.jar
        $NINJA_EXECUTABLE -C "$SWIPL_BUILD_DIR"
        $NINJA_EXECUTABLE install -C "$SWIPL_BUILD_DIR"
    fi
    
    SPDLOG_INSTALL_DIR=$INSTALL_DIR/spdlog
    PKG_CONFIG_PATH="$SPDLOG_INSTALL_DIR"/lib/pkgconfig:"$PKG_CONFIG_PATH"
    if [ ! -d "$SPDLOG_INSTALL_DIR" ]; then
        set -e  # Exit immediately if a command fails
        set -o pipefail
        
        # Create a working directory
        SPDLOG_SRC_DIR=$EXT_DIR/spdlog
        SPDLOG_BUILD_DIR=$SPDLOG_SRC_DIR/build
        mkdir -p "$SPDLOG_SRC_DIR"
        mkdir -p "$SPDLOG_INSTALL_DIR"
        cd "$SPDLOG_SRC_DIR" || exit
        
        # ==============================
        # 1. Build and Install spdlog
        # ==============================
        echo "📦 Building spdlog..."
        wget -c https://github.com/gabime/spdlog/archive/refs/tags/v1.15.2.tar.gz -O spdlog-1.15.2.tar.gz
        tar xf spdlog-1.15.2.tar.gz
        mkdir -p "$SPDLOG_BUILD_DIR"
        $CMAKE_EXECUTABLE -B "$SPDLOG_BUILD_DIR" -S spdlog-1.15.2 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$SPDLOG_INSTALL_DIR" \
        -DSPDLOG_BUILD_SHARED=OFF \
        -DSPDLOG_BUILD_TESTS=OFF
        
        $CMAKE_EXECUTABLE --build "$SPDLOG_BUILD_DIR" -j$(nproc)
        $CMAKE_EXECUTABLE --install "$SPDLOG_BUILD_DIR"
    fi
    
    BOOST_INSTALL_DIR=$INSTALL_DIR/boost
    if [ ! -d "$BOOST_INSTALL_DIR" ]; then
        set -e  # Exit immediately if a command fails
        set -o pipefail
        
        # Create a working directory
        BOOST_SRC_DIR=$EXT_DIR/boost
        mkdir -p "$BOOST_SRC_DIR"
        mkdir -p "$BOOST_INSTALL_DIR"
        cd "$BOOST_SRC_DIR" || exit
        
        # ==============================
        # 1. Build and Install boost
        # ==============================
        echo "📦 Building boost..."
        wget -c https://archives.boost.io/release/1.88.0/source/boost_1_88_0.tar.gz -O boost_1_88_0.tar.gz
        tar xf boost_1_88_0.tar.gz
        cd boost_1_88_0
        ./bootstrap.sh --prefix="$BOOST_INSTALL_DIR" --with-libraries=python
        CONFIG_FILE="project-config.jam"
        echo "# Boost Python configuration" > $CONFIG_FILE
        PYTHONS=("3.8" "3.10" "3.12")
        for ver in "${PYTHONS[@]}"; do
            pybin="/usr/bin/python$ver"
            if [ ! -f "$pybin" ]; then
                echo "Python $ver not found. Skipping Boost.Python for this version."
                continue
            fi
            pyinc="/usr/include/python${ver}"
            echo "using python : $ver : $pybin : $pyinc ;" >> $CONFIG_FILE
        done
        for ver in "${PYTHONS[@]}"; do
            echo "Building Boost.Python for Python $ver..."
            ./b2 --prefix="$BOOST_INSTALL_DIR" --build-dir=../build-"$ver" python="$ver" variant=release threading=multi link=shared runtime-link=shared install
        done
    fi
    
    MONGOC_INSTALL_DIR=$INSTALL_DIR/mongoc
    PKG_CONFIG_PATH="$MONGOC_INSTALL_DIR"/lib/pkgconfig:"$PKG_CONFIG_PATH"
    if [ ! -d "$MONGOC_INSTALL_DIR" ]; then
        set -e  # Exit immediately if a command fails
        set -o pipefail
        
        # Create a working directory
        MONGOC_SRC_DIR=$EXT_DIR/mongoc
        MONGOC_BUILD_DIR=$MONGOC_SRC_DIR/build
        mkdir -p "$MONGOC_BUILD_DIR"
        cd "$MONGOC_SRC_DIR" || exit
        
        # ==============================
        # 1. Build and Install mongoc
        # ==============================
        echo "📦 Building mongoc..."
        VERSION="2.0.0"
        wget -c "https://github.com/mongodb/mongo-c-driver/archive/refs/tags/$VERSION.tar.gz" \
        --output-document="mongo-c-driver-$VERSION.tar.gz"
        tar xf "mongo-c-driver-$VERSION.tar.gz"
        mkdir -p "$MONGOC_BUILD_DIR"
        cd "mongo-c-driver-$VERSION" || exit
        $CMAKE_EXECUTABLE -S . -B "$MONGOC_BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DBUILD_VERSION="$VERSION" \
        -DENABLE_MONGOC=OFF
        $CMAKE_EXECUTABLE --build "$MONGOC_BUILD_DIR" --config RelWithDebInfo --parallel
        $CMAKE_EXECUTABLE --install "$MONGOC_BUILD_DIR" --prefix "$MONGOC_INSTALL_DIR" --config RelWithDebInfo
        $CMAKE_EXECUTABLE -D ENABLE_MONGOC=ON "$MONGOC_BUILD_DIR"
        $CMAKE_EXECUTABLE --build "$MONGOC_BUILD_DIR" --config RelWithDebInfo --parallel
        $CMAKE_EXECUTABLE --install "$MONGOC_BUILD_DIR" --prefix "$MONGOC_INSTALL_DIR" --config RelWithDebInfo
    fi
    PATH=$PATH LD_LIBRARY_PATH="$LD_LIBRARY_PATH" PKG_CONFIG_PATH="$PKG_CONFIG_PATH" CMAKE_EXECUTABLE="$CMAKE_EXECUTABLE" DBoost_ROOT="$BOOST_INSTALL_DIR" "$KNOWROB_CONNECTOR_DIR"/build_knowrob_connector.sh
fi

end_time=$(date +%s)
elapsed=$(( end_time - start_time ))

echo "Build completed in $elapsed seconds"