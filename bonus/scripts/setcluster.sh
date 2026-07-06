#!/bin/bash

REPO_NAME="hsaktiwy-ception"
TARGET_APP_REPO="https://github.com/hsaktiwy/hsaktiwy-ception.git"
SOURCE_DIR="./hsaktiwy-ception" # Ensure this points to your prepared source files

echo "1. Setting up K3d Cluster (Exposing 8181 for GitLab)..."
sudo k3d cluster create MyWellingtoni \
  -p "8888:8888@loadbalancer" \
  -p "80:80@loadbalancer" \
  -p "8443:443@loadbalancer" \
  -p "8181:8181@loadbalancer" \
  --k3s-arg "--disable=traefik@server:0"

echo "2. Setting up Namespaces..."
sudo kubectl create namespace argocd
sudo kubectl create namespace dev
sudo kubectl create namespace gitlab

echo "3. Deploying External Databases (PostgreSQL & Redis)..."
sudo helm repo add bitnami https://charts.bitnami.com/bitnami
sudo helm repo update

sudo helm upgrade --install gitlab-postgresql bitnami/postgresql \
  --namespace gitlab \
  --set auth.database=gitlabhq_production \
  --set auth.username=gitlab \
  --set auth.password=gitlabpassword \
  --set auth.postgresPassword=postgrespassword \
  --set primary.persistence.enabled=false \
  --set primary.resourcesPreset=none \
  --set primary.livenessProbe.initialDelaySeconds=120 \
  --set primary.readinessProbe.initialDelaySeconds=120

sudo helm upgrade --install gitlab-redis bitnami/redis \
  --namespace gitlab \
  --set architecture=standalone \
  --set auth.enabled=false \
  --set master.persistence.enabled=false \
  --set master.livenessProbe.initialDelaySeconds=120 \
  --set master.readinessProbe.initialDelaySeconds=120

echo "   -> Waiting for databases to initialize..."
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=postgresql --timeout=300s
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=redis --timeout=300s

echo "4. Installing GitLab (Pinned to v10.1.0)..."
sudo helm repo add gitlab https://charts.gitlab.io/
sudo helm repo update

sudo helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --timeout 1800s \
  -f confs/version1.yml

echo "5. Patching GitLab to use LoadBalancer on Port 8181..."
# This hooks the internal service to the K3d port we exposed in Step 1
sudo kubectl patch svc gitlab-webservice-default -n gitlab -p '{"spec": {"type": "LoadBalancer"}}'

echo "6. Waiting for GitLab Webservice to stabilize (Using Rollout Status)..."
# Rollout status is much more reliable than pod selectors for Helm charts
sudo kubectl rollout status deployment/gitlab-webservice-default -n gitlab --timeout=900s

echo "7. Deploying ArgoCD Core Engine..."
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "8. Waiting for ArgoCD to stabilize..."
sudo kubectl rollout status deployment/argocd-server -n argocd --timeout=900s

echo "9. Extracting Passwords..."
ArgoCDPass=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
GitLabPass=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d)

echo "10. Pushing Code to GitLab (Push-to-Create)..."
git clone $TARGET_APP_REPO
cd "$SOURCE_DIR" || { echo "❌ Source directory $SOURCE_DIR not found"; exit 1; }

# Initialize and push directly to localhost:8181 (No port-forward needed!)
rm -rf .git
git init
git checkout -b master 2>/dev/null || git checkout -b main
git add .
git commit -m "Automated deployment commit"
git push -f "http://root:${GitLabPass}@localhost:8181/root/${REPO_NAME}.git" HEAD:master
cd - > /dev/null

echo "11. Authenticating ArgoCD to read the new Repository..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/${REPO_NAME}.git
  username: root
  password: ${GitLabPass}
EOF

echo "12. Triggering ArgoCD Application..."
# Fixed the typo here to match your actual file name
sudo kubectl apply -f confs/bootstrap-app.yaml

echo "====================================================="
echo "✅ INFRASTRUCTURE DEPLOYED & SYNCED SUCCESSFULLY"
echo "====================================================="
echo "ArgoCD UI: https://localhost:8443"
echo "ArgoCD -> Username: admin | Password: $ArgoCDPass"
echo "-----------------------------------------------------"
echo "GitLab UI: http://localhost:8181"
echo "GitLab -> Username: root  | Password: $GitLabPass"
echo "====================================================="
