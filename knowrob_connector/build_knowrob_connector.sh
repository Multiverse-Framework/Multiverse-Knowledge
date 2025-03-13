#!/bin/bash

cmake -S $PWD -B build -DCMAKE_INSTALL_PREFIX:PATH=$PWD
make -C build
cmake --install build