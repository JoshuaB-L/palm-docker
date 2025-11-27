# Running PALM Cases in Docker

This guide explains how to run PALM simulations inside the Docker container while keeping your job data on the host machine. The setup uses volume mounts to seamlessly map host directories into the container.

## Prerequisites

- Docker installed and running
- PALM Docker image built: `joshbl90/palm:latest`
- Job directory structure on host at: `/home/jmbl20/palm/current_version/JOBS/urban_environment`
- Host has at least 20 CPU cores available (or adjust `-X` parameter as needed)

## Quick Reference

| Task | Command |
|------|---------|
| **Interactive run (20 cores, manual prompt)** | See [Interactive Setup](#interactive-setup) |
| **Automated run (20 cores, no prompts)** | `./run_palm_case.sh` |
| **Custom core count** | `./run_palm_case.sh --np 4` |
| **Attach to running container** | `docker exec -it palm_interactive /bin/bash` |
| **View live logs** | `docker logs -f palm_interactive` |
| **Stop running job** | `docker kill palm_interactive` |

---

## Interactive Setup (Recommended for First Run)

Interactive mode allows you to see the PALM configuration summary and confirm before execution.

### Step 1: Start Interactive Container

```bash
# Clean up any old container and start fresh
docker rm -f palm_interactive || true

# Start a new detached container with volumes mounted
docker run --name palm_interactive -d \
  -v /home/jmbl20/palm/current_version/JOBS:/opt/palm/install/JOBS:rw \
  -e PALM_ROOT=/opt/palm/palm_model_system-master \
  -e PATH=/opt/palm/install/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -e OMPI_ALLOW_RUN_AS_ROOT=1 \
  -e OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
  joshbl90/palm:latest tail -f /dev/null
```

**What this does:**
- `--name palm_interactive`: names the container so you can reference it easily
- `-d`: runs in detached mode (container stays running in background)
- `-v /home/jmbl20/palm/current_version/JOBS:/opt/palm/install/JOBS:rw`: mounts your host JOBS folder into the container at `/opt/palm/install/JOBS` with read-write access
- `-e OMPI_ALLOW_RUN_AS_ROOT*`: allows MPI (OpenMPI) to run as root inside the container (necessary when running as root user)
- `tail -f /dev/null`: keeps container running indefinitely

### Step 2: Attach Shell to Container

```bash
docker exec -it palm_interactive /bin/bash
```

You should now have a root shell (`root@<container-id>:/#`) inside the container.

### Step 3: Navigate and Run PALM

Inside the container shell, run:

```bash
cd /opt/palm/install

# Run palmrun interactively with 20 cores
palmrun -r urban_environment -X 20 -a "d3#"
```

**Parameter meanings:**
- `-r urban_environment`: run identifier (job name)
- `-X 20`: number of cores/processors to use
- `-a "d3#"`: activation string (tells PALM which output to generate; `d3#` = 3D output)

### Step 4: Respond to Configuration Prompt

You will see output like:
```
#------------------------------------------------------------------------#
| palmrun                                   Thu Nov 27 11:57:13 UTC 2025 |
| Version: PALM 24.04                                                    |
|                                                                        |
| called on:               6b36243270b2                                  |
| config. identifier:      default (execute on IP: 127.0.0.1)            |
| running in:              interactive run mode                          |
| number of cores:         20                                            |
| ...
#------------------------------------------------------------------------#

 >>> everything o.k. (y/n) ?  
```

**Type `y` and press Enter** to confirm and start the simulation.

### Step 5: Monitor Execution

While PALM is running (in the same shell or from another terminal):

**Option A: Watch in current shell** — PALM will print progress as it runs.

**Option B: View logs from another terminal:**
```bash
docker logs -f palm_interactive
```

**Option C: Inspect temporary files (from another terminal):**
```bash
docker exec -it palm_interactive bash -c 'ls -la /opt/palm/install/tmp/urban_environment*'
docker exec -it palm_interactive bash -c 'cat /opt/palm/install/tmp/urban_environment.*/RUN_PROTOCOL | tail -50'
```

### Step 6: Retrieve Results

When PALM finishes, results are automatically in your host directory:

```bash
# On host machine
ls -lh /home/jmbl20/palm/current_version/JOBS/urban_environment/OUTPUT/
```

Output files include NetCDF files for 3D fields, time series, profiles, etc.

### Stopping an Interactive Run

**From the container shell:**
```bash
# Press Ctrl+C to interrupt palmrun
```

**From another terminal:**
```bash
# Graceful stop (SIGINT allows cleanup)
docker kill --signal=SIGINT palm_interactive

# Or immediate stop
docker stop palm_interactive
```

---

## Automated Setup (Non-Interactive)

For batch runs or when you don't need to confirm the configuration, use the provided helper script.

### Step 1: Make Script Executable

```bash
cd /home/jmbl20/Git/GitHub/palm-docker
chmod +x run_palm_case.sh
```

### Step 2: Run with Default Settings (20 Cores)

```bash
./run_palm_case.sh
```

The script will:
1. Start a new container with the same mounts and environment
2. Extract activation strings from `case_config.yml`
3. Run `palmrun` with `-v` (skip interactive prompt) and `-X 20` (20 cores)
4. Exit when PALM completes
5. Leave results in `/home/jmbl20/palm/current_version/JOBS/urban_environment/OUTPUT/`

### Step 3: Run with Custom Core Count

```bash
./run_palm_case.sh --np 4
```

Other options:
```bash
# Run with 8 cores
./run_palm_case.sh --np 8

# Override image name
IMAGE=myrepo/palm:custom ./run_palm_case.sh

# Override host JOBS directory
HOST_JOBS_DIR=/other/palm/JOBS ./run_palm_case.sh

# Run with specific user ownership (requires proper permissions)
./run_palm_case.sh --user $(id -u):$(id -g)

# Show help
./run_palm_case.sh --help
```

### Monitoring Automated Run

While the script runs, in another terminal:

```bash
# Watch Docker logs
docker logs -f <container-name>

# List running containers
docker ps -f ancestor=joshbl90/palm:latest

# Check output directory for new files
watch -n 5 'ls -lh /home/jmbl20/palm/current_version/JOBS/urban_environment/OUTPUT/ | tail -10'
```

---

## Configuration Details

### Job Configuration File

The job configuration is stored in:
```
/home/jmbl20/palm/current_version/JOBS/urban_environment/case_config.yml
```

**Current settings:**
```yaml
---
allowed_builds:
  - gfortran_default
  - intel_default

allowed_number_of_cores:
  - 2
  - 4
  - 20

activation_strings:
  - "d3#"

significant_digits_for_netcdf_checks:
  timeseries: 4
  profiles: 3
  other: 2
```

**Key fields:**
- `allowed_number_of_cores`: list of valid processor counts. Only these values can be passed with `-X` to palmrun.
- `activation_strings`: PALM output control strings. `d3#` = 3D NetCDF output. Other options: `restart`, `svfout`, `svfin`, `spinout`, etc.
- `significant_digits_for_netcdf_checks`: rounding precision for numerical comparisons in test suite.

### PALM Config File

The main PALM configuration is at:
```
/opt/palm/install/.palm.config.default
```

This file defines compilers, MPI settings, I/O paths, etc. It is **pre-configured** in the Docker image, so you typically don't need to modify it for basic runs.

---

## Troubleshooting

### Issue: "mpirun has detected an attempt to run as root"

**Root cause:** OpenMPI prevents root execution by default for safety.

**Solution:** The Docker setup includes environment variables to override this:
```bash
-e OMPI_ALLOW_RUN_AS_ROOT=1
-e OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
```

These are already in both the interactive container startup and the `run_palm_case.sh` script.

**Alternative (safer):** Run container as your user instead of root:
```bash
docker run --name palm_interactive -it \
  -u $(id -u):$(id -g) \
  -v /home/jmbl20/palm/current_version/JOBS:/opt/palm/install/JOBS:rw \
  -e PALM_ROOT=/opt/palm/palm_model_system-master \
  -e PATH=/opt/palm/install/bin:$PATH \
  joshbl90/palm:latest /bin/bash
```

Then inside, ensure `/opt/palm/install` directories are writable by your user, or use `sudo` as needed.

### Issue: "everything o.k. (y/n) ?" Prompt Hangs

**Root cause:** When running non-interactively (e.g., in a script), palmrun waits for input with no way to respond.

**Solution:** Use the `-v` flag (verbose/skip prompt) in non-interactive contexts:
```bash
palmrun -r urban_environment -X 20 -v -a "d3#"
```

This is already done in `run_palm_case.sh`.

### Issue: Permission Denied on `/opt/palm/install/tmp`

**Root cause:** When running as non-root user, you may not have write permission to `/opt/palm/install`.

**Solution:** 
1. Create necessary directories with correct ownership before starting the container:
   ```bash
   sudo mkdir -p /opt/palm/install/tmp
   sudo chown $(id -u):$(id -g) /opt/palm/install/tmp
   ```
2. Or run the container as root (as in the default setup).

### Issue: Output Files Not Written to Host

**Root cause:** Volume mount not correctly set up, or PALM writing to a different path.

**Verification:**
```bash
# Inside container:
docker exec -it palm_interactive bash -c 'mount | grep JOBS'
# Should show: /dev/xxx on /opt/palm/install/JOBS type ext4 (rw,relatime)

# Check output folder inside container:
docker exec -it palm_interactive bash -c 'ls -la /opt/palm/install/JOBS/urban_environment/OUTPUT/'

# Check host folder:
ls -la /home/jmbl20/palm/current_version/JOBS/urban_environment/OUTPUT/
```

If files exist in container but not on host, the mount is not properly bidirectional. Restart the container with the correct `-v` flag.

---

## Advanced Usage

### Running Multiple Jobs in Parallel

You can start multiple named containers, each running a different job:

```bash
# Job 1: 20 cores
docker run --name palm_job1 -d \
  -v /home/jmbl20/palm/current_version/JOBS:/opt/palm/install/JOBS:rw \
  -e PALM_ROOT=/opt/palm/palm_model_system-master \
  -e PATH=/opt/palm/install/bin:$PATH \
  -e OMPI_ALLOW_RUN_AS_ROOT=1 \
  -e OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
  joshbl90/palm:latest /bin/bash -c \
  'cd /opt/palm/install && palmrun -r urban_environment -X 20 -v -a "d3#"'

# Job 2: 10 cores (different config)
docker run --name palm_job2 -d \
  -v /home/jmbl20/palm/current_version/JOBS:/opt/palm/install/JOBS:rw \
  -e PALM_ROOT=/opt/palm/palm_model_system-master \
  -e PATH=/opt/palm/install/bin:$PATH \
  -e OMPI_ALLOW_RUN_AS_ROOT=1 \
  -e OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
  joshbl90/palm:latest /bin/bash -c \
  'cd /opt/palm/install && palmrun -r another_job -X 10 -v -a "d3#"'

# Monitor both
docker logs -f palm_job1 &
docker logs -f palm_job2 &
```

### Custom Activation Strings

Modify `case_config.yml` to enable different PALM outputs:

```yaml
activation_strings:
  - "d3#"           # 3D fields
  - "restart"       # Restart files for continuation runs
  - "svfout"        # SVF (state vector file) output
```

Then run:
```bash
palmrun -r urban_environment -X 20 -a "d3# restart" -v
```

### Building a Custom Docker Image with Different Compiler

Edit `palm-hpc.Dockerfile` to change the compiler (e.g., Intel Fortran instead of gfortran), then rebuild:

```bash
cd /home/jmbl20/Git/GitHub/palm-docker
docker build -f palm-hpc.Dockerfile -t myrepo/palm:intel .
```

Then use your custom image:
```bash
IMAGE=myrepo/palm:intel ./run_palm_case.sh
```

---

## File Structure Reference

```
Host Machine:
/home/jmbl20/palm/current_version/
  ├── JOBS/
  │   └── urban_environment/              ← Job directory (mounted into container)
  │       ├── case_config.yml             ← Job configuration (activation strings, core counts)
  │       ├── INPUT/                      ← Input files (p3d, static, dynamic, uv, etc.)
  │       │   ├── urban_environment_p3d
  │       │   ├── urban_environment_static
  │       │   ├── urban_environment_dynamic
  │       │   ├── urban_environment_uv
  │       │   ├── urban_environment_rlw
  │       │   └── urban_environment_rsw
  │       ├── MONITORING/                 ← PALM test monitoring (if palmtest was run)
  │       ├── OUTPUT/                     ← ⭐ Results written here (created by PALM)
  │       └── USER_CODE/                  ← Optional: user-defined source modifications

Docker Container:
/opt/palm/install/
  ├── JOBS/                               ← Volume-mounted from host JOBS/
  │   └── urban_environment/              ← Same as host, mounted at runtime
  │       ├── INPUT/
  │       └── OUTPUT/
  ├── .palm.config.default                ← PALM configuration
  ├── bin/                                ← Executables (palmrun, palmbuild, etc.)
  ├── install/                            ← Compiled PALM binary & libraries
  ├── tmp/                                ← Temporary working directory for PALM
  │   └── urban_environment.XXXXX/        ← Runtime temp files per execution
  └── rrtmg/                              ← RRTMG radiation library
```

---

## Quick Workflow Summary

### Workflow A: Interactive Run (Learn/Debug)

```bash
# Start container
docker rm -f palm_interactive || true
docker run --name palm_interactive -d \
  -v /home/jmbl20/palm/current_version/JOBS:/opt/palm/install/JOBS:rw \
  -e PALM_ROOT=/opt/palm/palm_model_system-master \
  -e PATH=/opt/palm/install/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -e OMPI_ALLOW_RUN_AS_ROOT=1 -e OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
  joshbl90/palm:latest tail -f /dev/null

# Attach and run
docker exec -it palm_interactive /bin/bash
# Inside container:
cd /opt/palm/install
palmrun -r urban_environment -X 20 -a "d3#"
# Respond 'y' to the prompt
```

### Workflow B: Automated Run (Batch/Production)

```bash
cd /home/jmbl20/Git/GitHub/palm-docker
chmod +x run_palm_case.sh
./run_palm_case.sh --np 20    # or just ./run_palm_case.sh for default 20 cores
```

Both workflows leave results in:
```
/home/jmbl20/palm/current_version/JOBS/urban_environment/OUTPUT/
```

---

## Support & Further Information

- **PALM Official Website:** https://www.palm-model.org/
- **PALM Documentation:** https://palm.muk.uni-hannover.de/trac/wiki
- **Docker Docs:** https://docs.docker.com/
- **OpenMPI Docs:** https://www.open-mpi.org/faq/

---

## Version Info

- **PALM Version:** 24.04
- **Base Image:** Ubuntu 20.04
- **Docker Image:** `joshbl90/palm:latest`
- **Compiler:** gfortran, mpif90 (OpenMPI)
- **Last Updated:** November 27, 2025
