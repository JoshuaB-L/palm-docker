# PALM Docker Container

Docker containerization of PALM (Parallelized Large-Eddy Simulation Model) for deployment on HPC systems and Linux workstations.

## Overview

This repository provides a Docker container with a fully configured PALM installation, including:
- PALM model system (master branch from GitLab)
- All required dependencies (GFortran, OpenMPI, NetCDF, FFTW3)
- Python tools and GUI components
- Pre-configured environment for running simulations

The container can be used directly with Docker or converted to Singularity/Apptainer format for HPC clusters.

## Prerequisites

### For Using Pre-built Container
- Docker Engine 20.10 or later
- At least 4 CPU cores recommended
- 8GB RAM minimum (16GB+ recommended for larger simulations)
- Internet connection to pull the image

### For Building from Source
- Docker Engine with BuildKit support
- 10GB free disk space
- Internet connection for downloading PALM and dependencies

## Quick Start - Running Pre-built Container

### 1. Pull the Container

```bash
docker pull joshbl90/palm:latest
```

### 2. Run Interactive Session

```bash
docker run -it joshbl90/palm:latest bash
```

### 3. Run a Test Simulation

Inside the container:

```bash
# Set MPI environment variables (required when running as root)
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# Run example simulation
palmrun -r example_cbl -c default -a "d3#" -X 4 -v -z
```

Or run directly from host:

```bash
docker run -it joshbl90/palm:latest bash -c "\
export OMPI_ALLOW_RUN_AS_ROOT=1 && \
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 && \
palmrun -r example_cbl -c default -a 'd3#' -X 4 -v -z"
```

### 4. Run PALM Test Suite

```bash
docker run -it joshbl90/palm:latest bash -c "\
export OMPI_ALLOW_RUN_AS_ROOT=1 && \
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 && \
palmtest --cases urban_environment_restart --cores 4"
```

## Running with Persistent Data

To save simulation results and use custom input files:

```bash
# Create directories on host
mkdir -p ~/palm_data/input
mkdir -p ~/palm_data/output

# Run with mounted volumes
docker run -it \
  -v ~/palm_data/input:/opt/palm/input \
  -v ~/palm_data/output:/opt/palm/output \
  joshbl90/palm:latest bash
```

## Available PALM Commands

Once inside the container, these commands are available:

- `palmrun` - Main command to run PALM simulations
- `palmtest` - Run test cases to verify installation
- `palmrungui` - GUI for PALM (requires X11 forwarding)
- `palm_csd` - Static driver for domain setup

## Environment Variables

The container sets the following environment variables:

- `PALM_ROOT=/opt/palm/palm_model_system-master` - PALM source directory
- `PATH` includes `/opt/palm/install/bin` - PALM executables location

## Troubleshooting

### MPI "Running as Root" Error

**Problem**: MPI refuses to run as root with error message.

**Solution**: Set these environment variables before running palmrun:
```bash
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
```

### Out of Memory Errors

**Problem**: Simulation crashes with memory errors.

**Solution**: Increase Docker memory limit in Docker Desktop settings or use `--memory` flag:
```bash
docker run -it --memory=16g joshbl90/palm:latest bash
```

### Display/GUI Issues

**Problem**: Cannot run palmrungui.

**Solution**: Enable X11 forwarding (Linux/macOS):
```bash
xhost +local:docker
docker run -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix joshbl90/palm:latest bash
```

### Slow Performance

**Problem**: Simulations run slowly.

**Solution**:
- Allocate more CPU cores: `docker run -it --cpus=8 joshbl90/palm:latest bash`
- Reduce number of cores in palmrun: `-X 2` instead of `-X 4`

## Building from Source (Optional)

If you need to rebuild the container with modifications:

### 1. Clone/Extract This Repository

```bash
cd palm-docker
```

### 2. Review Configuration

Edit `build.sh` if needed:
- Change `DOCKER_USERNAME` to your Docker Hub username
- Modify `IMAGE_TAG` if you want a different version tag

### 3. Build and Push

```bash
chmod +x build.sh
./build.sh
```

This will:
- Build the Docker image using `palm-hpc.Dockerfile`
- Push to Docker Hub (requires `docker login`)
- Optionally convert to Singularity if available

### Manual Build (Without Pushing)

```bash
docker build -f palm-hpc.Dockerfile --platform linux/amd64 -t palm:local .
```

## Converting to Singularity for HPC

On your HPC system (e.g., ARCHER2):

```bash
# Pull and convert
singularity build palm.sif docker://joshbl90/palm:latest

# Run interactively
singularity shell palm.sif

# Run simulation
singularity exec palm.sif bash -c "\
export OMPI_ALLOW_RUN_AS_ROOT=1 && \
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 && \
palmrun -r example_cbl -c default -a 'd3#' -X 4 -v -z"
```

## Directory Structure

```
palm-docker/
├── palm-hpc.Dockerfile    # Main Dockerfile for building PALM container
├── build.sh               # Automated build and push script
├── README.md              # This file
├── CLAUDE.md              # AI assistant guidance file
└── .history/              # Version history (can be ignored)
```

### Container Internal Structure

```
/opt/palm/
├── palm_model_system-master/   # PALM source code
│   ├── packages/               # PALM components
│   │   ├── dynamic_driver/
│   │   ├── gui/
│   │   ├── palm/model/         # Core PALM model
│   │   └── static_driver/
│   ├── docs/                   # Documentation
│   └── TESTS/                  # Test cases
└── install/                    # PALM installation
    └── bin/                    # Executables (palmrun, palmtest, etc.)
```

## Example Simulations

### Convective Boundary Layer (CBL)

```bash
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

palmrun -r example_cbl -c default -a "d3#" -X 4 -v -z
```

### Urban Environment

```bash
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

palmtest --cases urban_environment_restart --cores 4
```

### List Available Test Cases

```bash
ls /opt/palm/palm_model_system-master/TESTS/cases/
```

## System Requirements

### Minimum
- 4 CPU cores
- 8GB RAM
- 5GB disk space

### Recommended
- 8+ CPU cores
- 16GB+ RAM
- 20GB disk space for results

## Docker Hub Repository

Pre-built images are available at: https://hub.docker.com/repository/docker/joshbl90/palm

## Support and Resources

- **PALM Website**: https://palm.muk.uni-hannover.de/
- **PALM GitLab**: https://gitlab.palm-model.org/releases/palm_model_system
- **PALM Documentation**: Available in `/opt/palm/palm_model_system-master/docs/` inside container

## License

This Docker configuration is provided as-is. PALM itself is distributed under its own license - see PALM documentation for details.

## Version Information

- **PALM Version**: 24.04 (master branch)
- **Base Image**: Ubuntu 20.04
- **Compiler**: GFortran (GCC)
- **MPI**: OpenMPI
- **Last Updated**: January 2025
