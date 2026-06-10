#!/bin/bash
MASTER_IP=$1
TOKEN_PATH="/vagrant/confs/token"

# Quick verification check
if [ ! -f "$TOKEN_PATH" ]; then
    echo "Token file missing!"
    exit 1
fi

K3S_TOKEN=$(cat "$TOKEN_PATH")

echo "IP:$MASTER_IP :: Token:$K3S_TOKEN"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --node-ip 192.168.56.111 --server https://${MASTER_IP}:6443 --flannel-iface=eth1" K3S_TOKEN="$K3S_TOKEN" sh -