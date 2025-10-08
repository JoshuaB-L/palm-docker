#!/bin/bash

# Exit on error
set -e

# Configuration - replace with your Docker Hub username
DOCKER_USERNAME="joshbl90"
IMAGE_NAME="palm"
IMAGE_TAG="latest"
DOCKERFILE="palm-hpc.Dockerfile"

echo "Building Docker image using ${DOCKERFILE}..."
docker build -f ${DOCKERFILE} --platform linux/amd64 -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .

echo "Pushing to Docker Hub..."
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}

# If running on a system with Singularity installed
if command -v singularity &> /dev/null; then
    echo "Converting to Singularity..."
    singularity build palm.sif docker://${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
    
    echo "Testing PALM Singularity container..."
    singularity exec palm.sif palmtest --cases urban_environment_restart --cores 4
else
    echo "Singularity not found - skipping conversion and testing"
    echo "To convert on ARCHER2, run:"
    echo "singularity build palm.sif docker://${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
fi