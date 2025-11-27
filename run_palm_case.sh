#!/usr/bin/env bash
set -euo pipefail

# run_palm_case.sh
# Launch the PALM Docker image and run the `urban_environment` job in-place,
# writing output to the host path at `.../JOBS/urban_environment/OUTPUT`.
#
# Usage examples:
#  Make executable: `chmod +x run_palm_case.sh`
#  Run with defaults (image `joshbl90/palm:latest`, 1 MPI rank):
#    ./run_palm_case.sh
#  Run with 4 MPI ranks:
#    ./run_palm_case.sh --np 4
#  Override image or host palm dir:
#    IMAGE=myrepo/palm:custom HOST_PALM_DIR=/home/me/palm/current_version ./run_palm_case.sh

IMAGE=${IMAGE:-joshbl90/palm:latest}
HOST_JOBS_DIR=${HOST_JOBS_DIR:-/home/jmbl20/palm/current_version/JOBS}
JOB_NAME=${JOB_NAME:-urban_environment}
CONTAINER_JOBS_DIR=/opt/palm/install/JOBS
NP=${NP:-12}
# Run as root inside container to avoid permission issues with /opt/palm/install
USER_OPT=""

show_help(){
  sed -n '1,20p' "$0"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --np|-n)
      NP="$2"; shift 2;;
    --image)
      IMAGE="$2"; shift 2;;
    --host-dir)
      HOST_JOBS_DIR="$2"; shift 2;;
    --user)
      USER_OPT="-u $2"; shift 2;;
    --help|-h)
      show_help; exit 0;;
    *)
      echo "Unknown arg: $1" >&2; show_help; exit 2;;
  esac
done

HOST_JOB_DIR="$HOST_JOBS_DIR/$JOB_NAME"

if [ ! -d "$HOST_JOB_DIR" ]; then
  echo "Host job directory not found: $HOST_JOB_DIR" >&2
  exit 1
fi

echo "Running PALM job inside Docker image: $IMAGE"
echo "Host job dir: $HOST_JOB_DIR -> container path: $CONTAINER_JOBS_DIR/$JOB_NAME"
echo "MPI tasks: $NP"

# Create a helper script inside the container
CONTAINER_SCRIPT=$(cat <<'EOSCRIPT'
#!/bin/bash
set -euo pipefail

JOB_NAME="$1"
NP="$2"
CONTAINER_JOBS_DIR="$3"

JOB_DIR="$CONTAINER_JOBS_DIR/$JOB_NAME"

# Gather activation strings from case_config.yml
activation_list=""
if [ -f "$JOB_DIR/case_config.yml" ]; then
  activation_list=$(sed -n '/^activation_strings:/,/^[^ ]/p' "$JOB_DIR/case_config.yml" 2>/dev/null | sed -n '2,100p' | sed -e 's/^[[:space:]]*-//g' -e "s/['\"]//g" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi
activation_list=${activation_list:-"d3#"}

# Ensure OUTPUT dir exists
mkdir -p "$JOB_DIR/OUTPUT"

echo "Using activation strings: $activation_list"
echo "Job directory: $JOB_DIR"

# Switch to /opt/palm/install where .palm.config.default resides
cd /opt/palm/install

# Run palmrun from here; use -v to skip interactive confirmation and -X to set processors
palmrun -r "$JOB_NAME" -X "$NP" -v -a "$activation_list"
EOSCRIPT
)

docker run --rm -it \
  -v "$HOST_JOBS_DIR":"$CONTAINER_JOBS_DIR":rw \
  -e PALM_ROOT=/opt/palm/palm_model_system-master \
  -e PATH=/opt/palm/install/bin:$PATH \
  -e OMPI_ALLOW_RUN_AS_ROOT=1 \
  -e OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
  $USER_OPT \
  $IMAGE /bin/bash -c "$CONTAINER_SCRIPT" \
  -- "$JOB_NAME" "$NP" "$CONTAINER_JOBS_DIR"

echo "Docker run finished. Output should be available under: $HOST_JOB_DIR/OUTPUT"

