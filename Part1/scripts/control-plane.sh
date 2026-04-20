#!/bin/bash
echo "Installing K3s on the control plane node..."

# Force K3s to bind to the private network IP instead of the NAT IP
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip 192.168.56.110 --bind-address 192.168.56.110" sh -

# --- THE PERMISSIONS FIX ---
# Create the .kube folder, copy the root config, and give the vagrant user full ownership
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Automatically point kubectl to the unlocked config file every time the user logs in
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc
# ---------------------------

# Share the token so the worker node can join
cp /var/lib/rancher/k3s/server/node-token /vagrant/token