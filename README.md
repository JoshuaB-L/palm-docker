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

## Running PALM Simulations - Step by Step

This section provides detailed instructions for setting up and running PALM simulations inside the Docker container.

### Understanding PALM Directory Structure

PALM uses a specific directory structure for organizing simulations:

```
/opt/palm/install/
├── .palm.config.default          # Default configuration file
├── bin/                          # PALM executables
└── JOBS/                         # Simulation jobs directory
    └── <job_name>/               # Individual job directory (e.g., example_cbl)
        ├── INPUT/                # Input parameter files
        │   └── <job_name>_p3d    # Main parameter file
        ├── OUTPUT/               # Simulation output files
        ├── MONITORING/           # Runtime monitoring data
        └── RESTART/              # Restart files for continuation runs
```

### Running the Example CBL (Convective Boundary Layer) Case

The `example_cbl` case is a preconfigured example that simulates a convective boundary layer. Follow these steps:

#### Step 1: Start the Container with Persistent Storage

```bash
# Create a directory on your host system for PALM jobs
mkdir -p ~/palm_jobs

# Start container with volume mount
docker run -it -v ~/palm_jobs:/opt/palm/install/JOBS joshbl90/palm:latest bash
```

#### Step 2: Set Up the Example Case

Inside the container:

```bash
# Set MPI environment variables
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# Create job directory structure
mkdir -p /opt/palm/install/JOBS/example_cbl/INPUT

# Copy the example parameter file
cp /opt/palm/palm_model_system-master/packages/palm/model/tests/cases/example_cbl/INPUT/example_cbl_p3d \
   /opt/palm/install/JOBS/example_cbl/INPUT/

# Navigate to installation directory
cd /opt/palm/install
```

#### Step 3: Run the Simulation

```bash
palmrun -r example_cbl -c default -a "d3#" -X 4 -v -z
```

**Command explanation:**
- `-r example_cbl` - Run identifier (job name)
- `-c default` - Use default configuration file
- `-a "d3#"` - Activation strings (enables 3D data output)
- `-X 4` - Number of CPU cores to use
- `-v` - Verbose output
- `-z` - Force recompilation

#### Step 4: Check Results

After the simulation completes:

```bash
# View monitoring output
ls -lh /opt/palm/install/JOBS/example_cbl/MONITORING/

# Check run control file
cat /opt/palm/install/JOBS/example_cbl/MONITORING/example_cbl_rc

# List output files
ls -lh /opt/palm/install/JOBS/example_cbl/OUTPUT/
```

Results will also be available on your host system in `~/palm_jobs/example_cbl/`.

### Running Other Example Cases

PALM includes 24 test cases. Here are some common ones:

#### Urban Environment Case

```bash
# Set up the case
mkdir -p /opt/palm/install/JOBS/urban_environment/INPUT
cp /opt/palm/palm_model_system-master/packages/palm/model/tests/cases/urban_environment/INPUT/* \
   /opt/palm/install/JOBS/urban_environment/INPUT/

# Run the simulation
cd /opt/palm/install
palmrun -r urban_environment -c default -a "d3#" -X 4 -v -z
```

#### Listing All Available Test Cases

```bash
ls /opt/palm/palm_model_system-master/packages/palm/model/tests/cases/
```

Available cases include:
- `example_cbl` - Convective boundary layer
- `example_cbl_restart` - CBL with restart capability
- `urban_environment` - Urban canyon simulation
- `urban_environment_restart` - Urban case with restart
- `street_canyon` - Street canyon flow
- `wind_turbine_model` - Wind turbine simulation
- `warm_air_bubble_lcm` - Warm air bubble with cloud microphysics
- `oceanml` - Ocean mixed layer
- And many more...

### Understanding palmrun Output

When you run `palmrun`, you'll see:

1. **Configuration summary** - Shows compiler options, number of cores, and run parameters
2. **Compilation status** - Reports if executable needs building
3. **Input file copying** - Lists which input files are being used
4. **Execution progress** - Shows the simulation running
5. **Completion message** - Confirms successful completion

Example output structure:
```
*** palmrun will be executed. Please wait ...
*** creating executable and other sources for the local host
*** executable and other sources created
*** providing INPUT-files:
>>> INPUT: /opt/palm/install/JOBS/example_cbl/INPUT/example_cbl_p3d  to  PARIN
*** all INPUT-files provided
*** execution starts in directory "/opt/palm/install/tmp/example_cbl.xxxxx"
*** execute command: "mpirun -n 4 ./palm"
*** palmrun finished
```

### Customizing Simulations

To create your own simulation:

1. **Create job directory:**
   ```bash
   mkdir -p /opt/palm/install/JOBS/my_simulation/INPUT
   ```

2. **Create or copy parameter file:**
   ```bash
   # Start from an example
   cp /opt/palm/install/JOBS/example_cbl/INPUT/example_cbl_p3d \
      /opt/palm/install/JOBS/my_simulation/INPUT/my_simulation_p3d
   ```

3. **Edit parameters** using any text editor (nano, vi, etc.)

4. **Run your simulation:**
   ```bash
   cd /opt/palm/install
   palmrun -r my_simulation -c default -a "d3#" -X 4 -v -z
   ```

### One-Line Docker Commands for Quick Testing

Run complete simulation from host without entering container:

```bash
# Example CBL case
docker run -it -v ~/palm_jobs:/opt/palm/install/JOBS joshbl90/palm:latest bash -c "\
export OMPI_ALLOW_RUN_AS_ROOT=1 && \
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 && \
mkdir -p /opt/palm/install/JOBS/example_cbl/INPUT && \
cp /opt/palm/palm_model_system-master/packages/palm/model/tests/cases/example_cbl/INPUT/example_cbl_p3d \
   /opt/palm/install/JOBS/example_cbl/INPUT/ && \
cd /opt/palm/install && \
palmrun -r example_cbl -c default -a 'd3#' -X 4 -v -z"

# Check results on host
ls -lh ~/palm_jobs/example_cbl/MONITORING/
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

## Quick Reference - Common Commands

### List Available Test Cases

```bash
# Inside container
ls /opt/palm/palm_model_system-master/packages/palm/model/tests/cases/

# From host
docker run --rm joshbl90/palm:latest ls /opt/palm/palm_model_system-master/packages/palm/model/tests/cases/
```

### View PALM Version

```bash
# Inside container
cd /opt/palm/install && palmrun -v
```

### Clean Up Temporary Files

```bash
# Inside container
rm -rf /opt/palm/install/tmp/*
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
- **Last Updated**: October 2025
