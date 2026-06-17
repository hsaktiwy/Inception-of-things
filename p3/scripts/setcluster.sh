echo "4. Setting up K3d Cluster..."
sudo k3d cluster create MyWellingtoni -p "8888:8888@loadbalancer" -p "80:80@loadbalancer" -p "8443:443@loadbalancer"

echo "5. Setting up Namespaces..."
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

echo "6. Deploying ArgoCD Core Engine..."
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "7. Waiting for ArgoCD Control Plane Components to stabilize..."
# Fixed the cut-off selector string and added a safe timeout
sudo kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=900s

echo "8. Bootstrapping Application via Root Definition..."
sudo kubectl apply -f confs/bootstrap-app.yaml

# Wait for the application pod to be deployed by ArgoCD before forwarding

echo "Waiting for Willplayground to deploy..."
sudo kubectl wait --namespace dev --for=condition=ready pod --selector=app=willplayground --timeout=900s

# Expose App to localhost:8888
#sudo kubectl port-forward svc/willplayground-service -n dev 8888:8888 > /dev/null 2>&1 &
ArgoCDPass=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "$ArgoCDPass" > .argocd.admin.pass
echo "ArgoCD authentication credentials: {username:'admin', password:'$ArgoCDPass'}"
echo "ArgoCD is available at: https://localhost:8443"
echo "App is available at: http://localhost:8888"

