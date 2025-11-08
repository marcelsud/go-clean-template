# Fly.io SSH Docker Machine

Deploy an Ubuntu machine with Docker to Fly.io and access it via `fly ssh` commands.

## Prerequisites

- Fly.io CLI installed and authenticated (`flyctl auth login`)
- Fly.io account with payment method (machines require it)

## Quick Start

### 1. Launch the Machine

```bash
# Launch/create the app and deploy
fly launch --no-deploy --name go-clean-template-ssh-machine

# Deploy the machine
fly deploy

# Or use Make target
make fly-machine-deploy
```

### 2. Connect via Fly SSH

```bash
# Open interactive SSH console
fly ssh console -a go-clean-template-ssh-machine

# Execute a single command
fly ssh console -a go-clean-template-ssh-machine -C "docker ps"

# Run multiple commands
fly ssh console -a go-clean-template-ssh-machine -C "docker run hello-world && docker images"
```

### 3. Useful Commands

```bash
# Check machine status
fly status -a go-clean-template-ssh-machine

# List machines
fly machines list -a go-clean-template-ssh-machine

# View logs
fly logs -a go-clean-template-ssh-machine

# Scale machines
fly scale count 1 -a go-clean-template-ssh-machine

# Stop machines (they'll auto-start on next SSH)
fly scale count 0 -a go-clean-template-ssh-machine
```

### 4. Run Docker Commands

```bash
# Check Docker version
fly ssh console -a go-clean-template-ssh-machine -C "docker --version"

# Run a container
fly ssh console -a go-clean-template-ssh-machine -C "docker run --rm alpine echo 'Hello from Fly.io'"

# Pull and run images
fly ssh console -a go-clean-template-ssh-machine -C "docker pull nginx && docker run -d nginx"

# List running containers
fly ssh console -a go-clean-template-ssh-machine -C "docker ps"
```

### 5. Destroy the Machine

```bash
# Destroy the entire app and all resources
fly apps destroy go-clean-template-ssh-machine

# Or use Make target
make fly-machine-destroy
```

## Features

- ✓ Ubuntu 22.04 base
- ✓ Docker CE installed
- ✓ Auto-start/stop machines to save costs
- ✓ Access via `fly ssh console`
- ✓ Runs in Fly.io's global infrastructure
- ✓ Minimal cost when not in use (auto-stop)

## Cost Optimization

The configuration uses:
- `auto_stop_machines = "stop"` - Machines stop when idle
- `auto_start_machines = true` - Machines start on SSH connection
- `min_machines_running = 0` - No minimum, can scale to zero

This means you only pay when actively using the machine.

## Makefile Targets

```bash
make fly-machine-deploy    # Deploy the Fly.io machine
make fly-machine-console   # Open SSH console
make fly-machine-status    # Check machine status
make fly-machine-logs      # View logs
make fly-machine-destroy   # Destroy the app
```

## Example Workflows

### Deploy and Test an Application

```bash
# Start SSH session
fly ssh console -a go-clean-template-ssh-machine

# Inside the machine:
git clone https://github.com/your/repo
cd repo
docker build -t myapp .
docker run -p 8080:8080 myapp
```

### Run CI/CD Tasks

```bash
# Run tests in Docker
fly ssh console -a go-clean-template-ssh-machine -C "
  git clone https://github.com/your/repo /tmp/repo &&
  cd /tmp/repo &&
  docker run --rm -v \$(pwd):/app -w /app golang:1.21 go test ./...
"
```

### One-off Docker Tasks

```bash
# Build an image and export it
fly ssh console -a go-clean-template-ssh-machine -C "
  docker build -t myimage . &&
  docker save myimage | gzip > myimage.tar.gz
"
```

## Notes

- The machine runs Docker daemon automatically on startup
- Files are ephemeral unless using Fly volumes
- For persistent storage, consider adding Fly volumes
- The machine auto-stops when idle to save costs
