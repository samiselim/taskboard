#!/usr/bin/env bash
# Local Kubernetes with minikube (profile "taskboard", so your other minikube clusters are untouched).
#   ./up.sh          -> install the Helm chart directly (test your chart)
#   ./up.sh argocd   -> install Argo CD and let IT deploy the chart from your GitHub repo (GitOps)
set -euo pipefail
cd "$(dirname "$0")"

MODE="${1:-helm}"
PROFILE=taskboard
NAMESPACE=taskboard
CHART=../../deploy/helm/taskboard

if ! minikube status -p "$PROFILE" >/dev/null 2>&1; then
  minikube start -p "$PROFILE" --cpus 2 --memory 4096
fi
kubectl config use-context "$PROFILE"

echo "==> Building the images and loading them into minikube"
docker build --pull -t taskboard-backend:local ../../app/backend
docker build --pull -t taskboard-frontend:local ../../app/frontend
minikube -p "$PROFILE" image load taskboard-backend:local
minikube -p "$PROFILE" image load taskboard-frontend:local

if [ "$MODE" = "argocd" ]; then
  # Argo CD pulls the chart + values-local.yaml from GitHub: push your changes first!
  ../../gitops/install-argocd.sh ../../gitops/applications/taskboard-local.yaml
  echo "==> Waiting for Argo CD to deploy TaskBoard"
  until kubectl -n "$NAMESPACE" get deploy taskboard-backend >/dev/null 2>&1; do sleep 5; done
  kubectl -n "$NAMESPACE" rollout status deploy/taskboard-backend --timeout=5m
else
  echo "==> Installing the Helm chart"
  helm upgrade --install taskboard "$CHART" \
    --namespace "$NAMESPACE" --create-namespace \
    -f "$CHART/values-local.yaml" \
    --wait --timeout 5m

  echo "==> Running the chart's test (API directly + through the frontend)"
  helm test taskboard -n "$NAMESPACE" --logs
fi

kubectl -n "$NAMESPACE" get pods,svc,statefulset,pvc
cat <<MSG

✅ TaskBoard is running in minikube ($MODE mode).
   App:  kubectl -n $NAMESPACE port-forward svc/taskboard-frontend 3000:8080
         then open http://localhost:3000   (nginx forwards /api to the backend inside the cluster)
   API:  kubectl -n $NAMESPACE port-forward svc/taskboard-backend 8000:8000
         then open http://localhost:8000/api/docs
MSG
