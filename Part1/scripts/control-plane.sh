#!/bin/bash
echo "Installing K3s on the control plane node..."
echo "Installing K3s..."
curl -sfL https://get.k3s.io | sh INSTALL_K3S_EXEC="--node-ip 192.168.56.110 --bind-address 192.168.56.110" -
mkdir -p /home/vagrant/.kube
sud`o cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube/config
# Get the token for the worker nodes
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)

# Store the token for the workers to use`
echo $TOKEN > /vagrant/token