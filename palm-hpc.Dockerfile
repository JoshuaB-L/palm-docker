FROM ubuntu:20.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gfortran \
    g++ \
    make \
    cmake \
    coreutils \
    libopenmpi-dev \
    openmpi-bin \
    libnetcdff-dev \
    netcdf-bin \
    libfftw3-dev \
    python3-pip \
    python3-pyqt5 \
    flex \
    bison \
    ncl-ncarg \
    git \
    wget \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opt/palm

# Download and extract PALM
RUN wget https://gitlab.palm-model.org/releases/palm_model_system/-/archive/master/palm_model_system-master.zip && \
    unzip palm_model_system-master.zip && \
    rm palm_model_system-master.zip

# Install Python dependencies from all requirements files
WORKDIR /opt/palm/palm_model_system-master
RUN python3 -m pip install -r docs/requirements.txt && \
    python3 -m pip install -r packages/dynamic_driver/inifor/requirements.txt && \
    python3 -m pip install -r packages/gui/palmrungui/requirements.txt && \
    python3 -m pip install -r packages/palm/model/requirements.txt && \
    python3 -m pip install -r packages/static_driver/palm_csd/requirements.txt

# Create installation directory
RUN mkdir -p /opt/palm/install

# Set environment variables
ENV PALM_ROOT="/opt/palm/palm_model_system-master"
ENV install_prefix="/opt/palm/install"
ENV PATH="${install_prefix}/bin:${PATH}"

# Run the PALM installation
RUN cd ${PALM_ROOT} && \
    bash install -p ${install_prefix}

# Add PALM to PATH permanently
RUN echo "export PALM_ROOT=${PALM_ROOT}" >> /etc/bash.bashrc && \
    echo "export PATH=${install_prefix}/bin:\${PATH}" >> /etc/bash.bashrc

# Set working directory for when container starts
WORKDIR ${PALM_ROOT}

# Set default command
CMD ["/bin/bash"]