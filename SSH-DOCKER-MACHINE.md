# SSH Docker Machine

This setup provides an Ubuntu machine with Docker that you can access via SSH and destroy when done.

## Quick Start

### Build and Start the Machine

```bash
# Build the image
docker build -f Dockerfile.ssh-docker -t ssh-docker-machine .

# Run the container
docker run -d \
  --name ssh-docker-machine \
  --privileged \
  -p 2222:22 \
  ssh-docker-machine

# OR use docker-compose
docker-compose -f docker-compose.ssh-machine.yml up -d
```

### Connect via SSH

Default credentials:
- **User**: `sshuser`
- **Password**: `password`
- **Port**: `2222`

```bash
# Connect to the machine
ssh sshuser@localhost -p 2222
# Password: password

# Or using SSH with password inline (requires sshpass)
sshpass -p password ssh -o StrictHostKeyChecking=no sshuser@localhost -p 2222
```

### Run Commands via SSH

```bash
# Single command
ssh sshuser@localhost -p 2222 "docker ps"

# Multiple commands
ssh sshuser@localhost -p 2222 "docker run hello-world && docker ps -a"

# Using sudo (no password required)
ssh sshuser@localhost -p 2222 "sudo docker info"
```

### Stop and Remove the Machine

```bash
# Stop the container
docker stop ssh-docker-machine

# Remove the container
docker rm ssh-docker-machine

# OR using docker-compose
docker-compose -f docker-compose.ssh-machine.yml down
```

## SSH Key Authentication (Optional)

For passwordless access:

```bash
# Generate SSH key pair (if you don't have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_docker_machine

# Copy your public key to the container
ssh-copy-id -i ~/.ssh/id_rsa_docker_machine.pub -p 2222 sshuser@localhost

# Connect without password
ssh -i ~/.ssh/id_rsa_docker_machine -p 2222 sshuser@localhost
```

## Features

- ✓ Ubuntu 22.04 base
- ✓ Docker CE installed
- ✓ SSH server configured
- ✓ User `sshuser` with sudo access (no password required)
- ✓ User is in docker group (can run Docker commands)
- ✓ Privileged mode for Docker-in-Docker

## Use Cases

```bash
# Deploy and test applications
ssh sshuser@localhost -p 2222 "docker run -d -p 80:80 nginx"

# Run docker-compose projects
ssh sshuser@localhost -p 2222 "cd /tmp && git clone <repo> && cd <repo> && docker-compose up -d"

# Execute scripts
cat script.sh | ssh sshuser@localhost -p 2222 "bash -s"
```

## Security Notes

- This is intended for **development/testing only**
- Change the default password in production
- Consider using SSH keys instead of passwords
- The container runs in privileged mode for Docker-in-Docker
