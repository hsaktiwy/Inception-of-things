#!/bin/bash
MASTER_IP=$1
echo "Installing K3s on the worker node..."
echo "Installing K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip 192.168.56.111" K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=$(cat /vagrant/token) sh -