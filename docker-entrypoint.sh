#!/bin/bash
set -e

# Start Docker daemon in the background
dockerd-entrypoint.sh &

# Wait for Docker to be ready
echo "Waiting for Docker daemon to start..."
timeout 30 sh -c 'until docker info > /dev/null 2>&1; do sleep 1; done'

if docker info > /dev/null 2>&1; then
    echo "Docker daemon is running"
else
    echo "Failed to start Docker daemon"
    exit 1
fi

# Execute the command passed to the container
exec "$@"
