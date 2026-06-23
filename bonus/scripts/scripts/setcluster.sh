echo "4. Setting up K3d Cluster..."
sudo k3d cluster create MyWellingtoni -p "8888:8888@loadbalancer" -p "80:80@loadbalancer" -p "8443:443@loadbalancer" --k3s-arg "--disable=traefik@server:0"

echo "5. Setting up Namespaces..."
sudo kubectl create namespace argocd
sudo kubectl create namespace dev
sudo kubectl create namespace gitlab

echo "6. Gitlab Installing..."
helm repo add gitlab https://charts.gitlab.io/
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --timeout 600s \
  --set global.edition=ce \
  --set global.hosts.domain=localhost \
  --set global.hosts.https=false \
  --set certmanager.install=false \
  --set prometheus.install=false \
  --set gitlab-runner.install=false \
  --set gitlab.webservice.minReplicas=1 \
  --set gitlab.webservice.maxReplicas=1 \
  --set gitlab.sidekiq.minReplicas=1 \
  --set gitlab.sidekiq.maxReplicas=1 \
  --set gitlab.gitaly.minReplicas=1 \
  --set gitlab.gitaly.maxReplicas=1
echo "6.1 Waiting for GitLab Webservice to stabilize (This can take 5-10 minutes)..."
sudo kubectl wait --namespace gitlab --for=condition=ready pod --selector=app=webservice --timeout=3600s

echo "7. Deploying ArgoCD Core Engine..."
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

#echo "8. Waiting for ArgoCD Control Plane Components to stabilize..."
# Fixed the cut-off selector string and added a safe timeout
sudo kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=900s

echo "9. Bootstrapping Application via Root Definition..."
#sudo kubectl apply -f confs/bootstrap-app.yaml

# Wait for the application pod to be deployed by ArgoCD before forwarding

echo "waiting for willplayground to deploy..."
sudo kubectl wait --namespace dev --for=condition=ready pod --selector=app=willplayground --timeout=900s

# Extract Passwords
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
echo ""
echo "⚠️ NEXT STEPS REQUIRED:"
echo "1. Log into http://localhost with the root credentials."
echo "2. Create a new blank project named 'hsaktiwy-ception'."
echo "3. Push your repository to this local GitLab instance."
echo "4. Once the code is in GitLab, run: kubectl apply -f bootstrap-app-bonus.yaml"
