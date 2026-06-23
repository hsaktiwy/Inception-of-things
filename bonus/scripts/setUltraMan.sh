#!/bin/bash

echo "4. Setting up K3d Cluster..."
sudo k3d cluster create MyWellingtoni -p "8888:8888@loadbalancer" -p "80:80@loadbalancer" -p "8443:443@loadbalancer" --k3s-arg "--disable=traefik@server:0"

echo "5. Setting up Namespaces..."
sudo kubectl create namespace argocd
sudo kubectl create namespace dev
sudo kubectl create namespace gitlab

echo "6. Deploying External Databases (Required for GitLab v10+)..."
sudo helm repo add bitnami https://charts.bitnami.com/bitnami
sudo helm repo update

echo "   -> Installing PostgreSQL..."
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

echo "   -> Installing Redis..."
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

echo "8. Gitlab Installing (Pinned to v10.1.0)..."
sudo helm repo add gitlab https://charts.gitlab.io/
sudo helm repo update

sudo helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --timeout 1800s \
  --version 10.1.0 \
  -f confs/gitlab-values.yaml

echo "8.1 Waiting for GitLab Webservice to stabilize (This can take up to 30 minutes on local VMs)..."
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=webservice --timeout=3600s

echo "9. Deploying ArgoCD Core Engine..."
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "10. Waiting for ArgoCD Control Plane Components to stabilize..."
sudo kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=900s

echo "11. Extracting Passwords..."
ArgoCDPass=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
GitLabPass=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d)

echo "====================================================="
echo "✅ INFRASTRUCTURE DEPLOYED SUCCESSFULLY"
echo "====================================================="
echo "ArgoCD is available at: https://localhost:8443"
echo "ArgoCD Credentials   -> Username: admin | Password: $ArgoCDPass"
echo "-----------------------------------------------------"
echo "GitLab Internal UI Access:"
echo "Run: sudo kubectl port-forward -n gitlab svc/gitlab-webservice-default 8181:8181 &"
echo "Then browse to: http://localhost:8181"
echo "GitLab Credentials   -> Username: root  | Password: $GitLabPass"
echo "====================================================="
