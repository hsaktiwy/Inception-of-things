#!/bin/bash

echo "1. Installing Docker..."
sudo apt-get update && sudo apt-get install curl -y
curl -fsSL https://get.docker.com | sh -
sudo usermod -aG docker vagrant # Target explicitly to be safe

# Force the current shell script execution to recognize the new docker group membership
# without requiring a full logout/login sequence
     
echo "2. Installing K3d..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.9.0 bash

echo "3. Installing Kubectl..."
K_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/$K_VER/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
