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

echo "4. Setting up K3d Cluster..."
sudo k3d cluster create MyWellington

echo "5. Setting up Namespaces..."
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

echo "6. Deploying ArgoCD Core Engine..."
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "7. Waiting for ArgoCD Control Plane Components to stabilize..."
# Fixed the cut-off selector string and added a safe timeout
sudo kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=150s

echo "8. Bootstrapping Application via Root Definition..."
sudo kubectl apply -f /vagrant/confs/bootstrap-app.yaml