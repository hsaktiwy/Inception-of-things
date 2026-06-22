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
  --set master.persistence.enabled=false

echo "   -> Waiting for databases to initialize..."
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=postgresql --timeout=300s
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=redis --timeout=300s

echo "7. Creating GitLab v10.1.0 Values File..."
cat <<EOF > gitlab-values.yaml
global:
  edition: ce
  ingress:
    enabled: false
    tls:
      enabled: false
    configureCertmanager: false
  kas:
    enabled: false
  psql:
    host: gitlab-postgresql
    database: gitlabhq_production
    username: gitlab
    password:
      secret: gitlab-postgresql
      key: password
  redis:
    host: gitlab-redis-master
    password:
      enabled: false
  appConfig:
    lfs:
      enabled: false
    artifacts:
      enabled: false
    uploads:
      enabled: false
    packages:
      enabled: false

nginx-ingress:
  enabled: false

ai-gateway:
  enabled: false

gitlab-pages:
  enabled: false

spamcheck:
  enabled: false

mailroom:
  enabled: false

installCertmanager: false

certmanager-issuer:
  email: test@example.com

grafana:
  enabled: false

registry:
  enabled: false

prometheus:
  install: false

gitlab-runner:
  install: false

gitlab-exporter:
  enabled: false
gitlab:
  webservice:
    minReplicas: 1
    maxReplicas: 1
    resources:
      requests:
        memory: 600Mi
        cpu: 200m
  sidekiq:
    minReplicas: 1
    maxReplicas: 1
    resources:
      requests:
        memory: 200Mi
        cpu: 100m
  toolbox:
    enabled: false
  gitaly:
    minReplicas: 1
    maxReplicas: 1
    persistence:
      enabled: false
  gitlab-shell:
    replicaCount: 1
EOF

echo "8. Gitlab Installing (Pinned to v10.1.0)..."
sudo helm repo add gitlab https://charts.gitlab.io/
sudo helm repo update

sudo helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --timeout 1800s \
  --version 10.1.0 \
  -f gitlab-values.yaml

echo "8.1 Waiting for GitLab Webservice to stabilize (This can take up to 30 minutes on local VMs)..."
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app.kubernetes.io/name=webservice --timeout=1800s

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
