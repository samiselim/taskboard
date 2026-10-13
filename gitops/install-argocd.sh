#!/usr/bin/env bash
# Install Argo CD (it's just a Helm chart) and register ONE Application.
# Works the same on minikube and on EKS: it uses your current kubectl context.
#
#   ./gitops/install-argocd.sh gitops/applications/taskboard-local.yaml   # minikube
#   ./gitops/install-argocd.sh gitops/applications/taskboard-prod.yaml    # EKS
set -euo pipefail
APP_FILE="${1:?Usage: $0 <application-file>}"

echo "==> Target cluster: $(kubectl config current-context)"

echo "==> Installing Argo CD (Helm chart argo/argo-cd)"
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update argo >/dev/null
helm upgrade --install argocd argo/argo-cd --version 10.10.3 \
  --namespace argocd --create-namespace \
  --wait --timeout 10m

echo "==> Registering the Application: $APP_FILE"
kubectl apply -f "$APP_FILE"

cat <<MSG

✅ Argo CD is running and watching your repository.
   Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
   UI:       kubectl -n argocd port-forward svc/argocd-server 8080:443   ->  https://localhost:8080  (user: admin)
   Status:   kubectl -n argocd get applications
MSG
