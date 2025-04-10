# Multiverse Knowledge

## Local Installation

### Dependencies

As dependencies we need to install the following packages:

```bash
sudo apt update
sudo apt install \
        wget gdb g++ clang cmake make doxygen \
        libeigen3-dev \
        libspdlog-dev \
        libraptor2-dev \
        librdf0 \
        librdf0-dev \
        libmongoc-1.0-0 \
        libmongoc-dev \
        libgtest-dev \
        libfmt-dev \
        libjsoncpp-dev \
        libc++abi1 \
        software-properties-common
```

SWI Prolog is needed for the knowrob package. The following packages are needed for the

```bash
sudo apt-add-repository -y ppa:swi-prolog/stable
sdu apt update
sudo apt install -y swi-prolog*
# you also need to export this environment variable
export SWI_HOME_DIR=/usr/lib/swi-prolog
export LD_LIBRARY_PATH=/usr/lib/swi-prolog/lib/x86_64-linux:$LD_LIBRARY_PATH
```

We need to have glibcxx_3.4.21 for the existing shared libraries. So if you do not want
to build knowrob yourself, you need to install the following packages:

```bash
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install gcc-11 g++-11 -y
```

### Building and Environment Setup

To install this package run 

```bash
./build_knowrob_connector.sh
```

This will build a shared library and copy it to the `lib` directory.

Then you need to set the `LD_LIBRARY_PATH` environment variable to include the `lib` directory. You can do this by running:

```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/lib
```

Additionally you need to set the `PYTHONPATH` environment variable to include the `dist-packages` directory. You can do this by running:

```bash
export PYTHONPATH=$PYTHONPATH:$(pwd)/dist-packages
```

### Usage

Download [this](https://nc.uni-bremen.de/index.php/s/Pc8am8SpoQLA9cF), open it and follow the instructions

Run `multiverse_server`

```bash
cd multiverse/multiverse_server
./multiverse_server
```

Run the simulation

```bash
./multiverse/mujoco-3.3.0/bin/simulate ./resources/montessory_toys.xml
```

To test this package in Python run

```bash
python3 scripts/multiverse_reasoner_test.py 
```

## Using Docker

To use the docker image, build it with:

```bash
docker build -t knowrob_connector ...
```

Then run the image with:

```bash
docker run --rm -it --entrypoint bash kconnector:latest
```

and run the following commands to test the package:

```bash
python scripts/multiverse_reasoner_test.py
````