#!/bin/bash

echo "========================================================="
echo "🧨 INITIATING FULL ENVIRONMENT CLEANUP"
echo "========================================================="

echo "1. Destroying any existing K3d clusters..."
# We use '|| true' so the script doesn't fail if no clusters exist
sudo k3d cluster delete --all || true

echo "2. Uninstalling K3d binary..."
sudo rm -f /usr/local/bin/k3d

echo "3. Uninstalling Kubectl binary..."
sudo rm -f /usr/local/bin/kubectl
# Remove kubectl config files and cache
sudo rm -rf ~/.kube

echo "4. Uninstalling Docker and its components..."
# Stop docker services first
sudo systemctl stop docker.socket || true
sudo systemctl stop docker.service || true
sudo systemctl stop containerd.service || true

# Purge all docker-related packages installed by the convenience script
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

# Remove leftover dependencies
sudo apt-get autoremove -y --purge

echo "5. Wiping leftover system data and volumes..."
# WARNING: This completely deletes all Docker images, containers, and volumes
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker
sudo rm -rf ~/.docker

echo "========================================================="
echo "✅ ENVIRONMENT CLEANED SUCCESSFULLY"
echo "Your system is now a blank slate. You can safely run your installation scripts."
echo "========================================================="
