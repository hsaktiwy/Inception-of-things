#!/bin/bash

echo "4. Setting up K3d Cluster..."
sudo k3d cluster create MyWellingtoni -p "8888:8888@loadbalancer" -p "80:80@loadbalancer" -p "8443:443@loadbalancer" --k3s-arg "--disable=traefik@server:0"

echo "5. Setting up Namespaces..."
sudo kubectl create namespace argocd
sudo kubectl create namespace dev
sudo kubectl create namespace gitlab

echo "6. Deploying External Databases (Required for GitLab v10+)..."
# Add Bitnami repository for the databases
sudo helm repo add bitnami https://charts.bitnami.com/bitnami
sudo helm repo update

echo "   -> Installing PostgreSQL..."
sudo helm upgrade --install gitlab-postgresql bitnami/postgresql \
  --namespace gitlab \
  --set auth.database=gitlabhq_production \
  --set auth.username=gitlab \
  --set auth.password=gitlabpassword \
  --set auth.postgresPassword=postgrespassword \
  --set primary.persistence.enabled=false

echo "   -> Installing Redis..."
sudo helm upgrade --install gitlab-redis bitnami/redis \
  --namespace gitlab \
  --set architecture=standalone \
  --set auth.enabled=false \
  --set master.persistence.enabled=false

echo "   -> Waiting for databases to initialize..."
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=postgresql --timeout=300s
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=redis --timeout=300s

echo "7. Gitlab Installing (Latest Version)..."
sudo helm repo add gitlab https://charts.gitlab.io/
sudo helm repo update

sudo helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --timeout 900s \
  --set global.edition=ce \
  --set global.hosts.domain=localhost \
  --set global.hosts.https=false \
  --set installCertmanager=false \
  --set certmanager-issuer.email=test@example.com \
  --set prometheus.install=false \
  --set gitlab-runner.install=false \
  --set gitlab.webservice.minReplicas=1 \
  --set gitlab.webservice.maxReplicas=1 \
  --set gitlab.sidekiq.minReplicas=1 \
  --set gitlab.sidekiq.maxReplicas=1 \
  --set gitlab.gitaly.minReplicas=1 \
  --set gitlab.gitaly.maxReplicas=1 \
  `# --- EXTERNAL DATABASE CONNECTIONS ---` \
  --set global.psql.host=gitlab-postgresql \
  --set global.psql.database=gitlabhq_production \
  --set global.psql.username=gitlab \
  --set global.psql.password.secret=gitlab-postgresql \
  --set global.psql.password.key=password \
  --set global.redis.host=gitlab-redis-master \
  `# --- BYPASS OBJECT STORAGE ERRORS ---` \
  --set registry.enabled=false \
  --set gitlab.toolbox.enabled=false \
  --set global.appConfig.lfs.enabled=false \
  --set global.appConfig.artifacts.enabled=false \
  --set global.appConfig.uploads.enabled=false \
  --set global.appConfig.packages.enabled=false \
  `# --- EXTREME RESOURCE CRUSHING ---` \
  --set gitlab.kas.enabled=false \
  --set gitlab.gitlab-exporter.enabled=false \
  --set gitlab.webservice.resources.requests.memory=512Mi \
  --set gitlab.webservice.resources.requests.cpu=100m \
  --set gitlab.sidekiq.resources.requests.memory=512Mi \
  --set gitlab.sidekiq.resources.requests.cpu=100m

echo "7.1 Waiting for GitLab Webservice to stabilize (This can take 5-10 minutes)..."
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app=webservice --timeout=3600s

echo "8. Deploying ArgoCD Core Engine..."
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "9. Waiting for ArgoCD Control Plane Components to stabilize..."
sudo kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=900s

echo "10. Extracting Passwords..."
ArgoCDPass=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
GitLabPass=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d)

echo "====================================================="
echo "✅ INFRASTRUCTURE DEPLOYED SUCCESSFULLY"
echo "====================================================="
echo "ArgoCD is available at: https://localhost:8443"
echo "ArgoCD Credentials   -> Username: admin | Password: $ArgoCDPass"
echo "-----------------------------------------------------"
echo "GitLab is available at: http://localhost"
echo "GitLab Credentials   -> Username: root  | Password: $GitLabPass"
echo "====================================================="
