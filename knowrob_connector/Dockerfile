# Dockerfile of the base image: https://github.com/IntEL4CoRo/docker-stacks/blob/remote-desktop/Dockerfile
FROM intel4coro/base-notebook:20.04-noetic-vnc

# Path to the default ROS workspace
ENV ROS_WS=${HOME}/workspace/ros

#============= Install extra software packages =============#

# Install Redland, Raptor2, libmongoc, spdlog, fmt, gtest
# Source: https://github.com/knowrob/knowrob/blob/dev/docker/noetic_base.Dockerfile
USER root
RUN apt update && \
    apt install -y \
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

# Install glibcxx_3.40.31 (Not completly sure why this is suddenly needed)
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt update
RUN apt install gcc-11 g++-11 -y

# Install SWI Prolog
# Source: https://www.swi-prolog.org/build/PPA.html
USER root
RUN apt-add-repository -y ppa:swi-prolog/stable
RUN apt update && \
    apt install -y swi-prolog*
ENV SWI_HOME_DIR=/usr/lib/swi-prolog
ENV LD_LIBRARY_PATH=/usr/lib/swi-prolog/lib/x86_64-linux:$LD_LIBRARY_PATH

USER ${NB_USER}
# WORKDIR ${HOME}
WORKDIR ${ROS_WS}/src
# RUN source ${ROS_WS}/devel/setup.bash 

# Clone the specified repository
# RUN git clone --branch KnowRobIntegration --single-branch https://github.com/sasjonge/Multiverse-Knowledge.git
COPY .. ${ROS_WS}/src/Multiverse-Knowledge/knowrob_connector

# Change directory to the specified folder
WORKDIR ${ROS_WS}/src/Multiverse-Knowledge/knowrob_connector

# Build the connector using CMake
USER root
RUN mkdir build
WORKDIR ${ROS_WS}/src/Multiverse-Knowledge/knowrob_connector
RUN ./build_knowrob_connector.sh
RUN ./copy_knowrob_to_python.sh

# Add paths for testing on cli
RUN echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/jovyan/workspace/ros/src/Multiverse-Knowledge/knowrob_connector/lib' >> /home/jovyan/.bashrc && \
    echo 'export PYTHONPATH=$PYTHONPATH:/home/jovyan/workspace/ros/src/Multiverse-Knowledge/knowrob_connector/dist-packages' >> /home/jovyan/.bashrc