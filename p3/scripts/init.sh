#!/bin/bash

echo "1. Installing Docker..."
sudo apt update && sudo apt install curl -y
curl -fsSL https://get.docker.com | sh -
# Give the vagrant user permission to run docker without sudo
sudo usermod -aG docker $USER

echo "2. Installing K3d..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.0.0 bash

echo "3. Installing Kubectl..."
# Get the version number of the latest stable release
K_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
# Download the binary
curl -LO "https://dl.k8s.io/release/$K_VER/bin/linux/amd64/kubectl"
# Install it into the system path
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
