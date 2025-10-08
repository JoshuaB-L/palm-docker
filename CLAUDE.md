# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository containerizes PALM (Parallelized Large-Eddy Simulation Model) for deployment on HPC systems, particularly ARCHER2. The project builds a Docker image that can be converted to Singularity/Apptainer format for use on HPC clusters.

## Build and Deployment

### Building the Docker Image

```bash
# Build and push to Docker Hub (requires Docker Hub credentials)
./build.sh
```

The build script:
- Builds the Docker image using `palm-hpc.Dockerfile`
- Pushes to Docker Hub (username: joshbl90)
- Optionally converts to Singularity format if available
- Runs test case `urban_environment_restart` with 4 cores

### Manual Build

```bash
# Build only
docker build -f palm-hpc.Dockerfile --platform linux/amd64 -t joshbl90/palm:latest .

# Convert to Singularity (on HPC system)
singularity build palm.sif docker://joshbl90/palm:latest

# Test PALM
singularity exec palm.sif palmtest --cases urban_environment_restart --cores 4
```

## Architecture

### Dockerfile Structure (palm-hpc.Dockerfile)

1. **Base**: Ubuntu 20.04
2. **Dependencies**: Installs Fortran compiler, MPI (OpenMPI), NetCDF, FFTW3, Python 3 with PyQt5
3. **PALM Installation**: Downloads PALM from GitLab (master branch), installs Python requirements from multiple packages, runs installation to `/opt/palm/install`
4. **Environment**: Sets `PALM_ROOT=/opt/palm/palm_model_system` and adds install directory to PATH

### PALM Components

The PALM installation includes multiple packages with separate requirements:
- `docs/` - Documentation
- `packages/dynamic_driver/inifor/` - INIFOR initialization tool
- `packages/gui/palmrungui/` - GUI interface
- `packages/palm/model/` - Core PALM model
- `packages/static_driver/palm_csd/` - Static driver for domain setup

### Build Configuration

- **Platform**: `linux/amd64` (required for ARCHER2 compatibility)
- **PALM Installation Prefix**: `/opt/palm/install`
- **Working Directory**: `/opt/palm/palm_model_system`

## Modifying Dependencies

When updating system or Python dependencies:
- System packages go in the first `apt-get install` block (palm-hpc.Dockerfile:7-27)
- Python requirements are installed from PALM's own requirements files (palm-hpc.Dockerfile:40-44)
- Any additional Python packages should be added after these installations
