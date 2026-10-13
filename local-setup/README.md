# Local Setup

Two ways to run TaskBoard on your laptop. Both only need **Docker**.

## Option A: Docker Compose (the app)
```bash
cd local-setup
docker compose up --build
```
| URL | What |
|-----|------|
| http://localhost:3000 | Frontend (nginx serves the static export and forwards `/api` to the backend, like CloudFront) |
| http://localhost:8000/api/docs | Backend API documentation |
| http://localhost:8000/metrics | Prometheus metrics |

Stop with `Ctrl+C`, then `docker compose down` (add `-v` to also delete the database volume).

### Frontend hot reload (optional, needs Node.js 22)
```bash
docker compose up -d db backend          # API on http://localhost:8000 (CORS allows localhost:3000)
cd ../app/frontend && npm install
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000 npm run dev    # http://localhost:3000 with hot reload
```

## Option B: SonarQube locally
```bash
docker compose --profile sonar up -d sonarqube        # http://localhost:9000  (admin / admin, then change it)
```
Create a project `taskboard-backend` with a token, then analyse the backend:
```bash
docker run --rm --network taskboard_default \
  -e SONAR_HOST_URL=http://sonarqube:9000 -e SONAR_TOKEN=<token> \
  -v "$PWD/../app/backend:/usr/src" sonarsource/sonar-scanner-cli
```

## Option C: Kubernetes with minikube (the Helm chart)
Tests the real chart (backend Deployment + PostgreSQL StatefulSet + PVC) on a local cluster.
Needs `minikube`, `kubectl` and `helm`. The scripts use a separate minikube **profile** called `taskboard`.
```bash
cd local-setup/minikube
./up.sh      # start minikube, build + load the image, helm install, helm test
./down.sh    # delete the taskboard profile (or: minikube stop -p taskboard)
```
Values used: [`values-local.yaml`](../deploy/helm/taskboard/values-local.yaml) (frontend enabled, plain Secret, default StorageClass, no ALB).

Open the app: `kubectl -n taskboard port-forward svc/taskboard-frontend 3000:8080`, then http://localhost:3000
(the frontend pod forwards `/api` to the backend Service inside the cluster).
Compare it with [`values-prod.yaml`](../deploy/helm/taskboard/values-prod.yaml): same chart, different values.

## Option D: Argo CD on minikube (GitOps)
Argo CD is installed like any Helm chart, then ONE `Application` tells it which repo/folder/values to watch.
Push the project to **your public GitHub repository** first, and set `repoURL` in
[`gitops/applications/taskboard-local.yaml`](../gitops/applications/taskboard-local.yaml).
```bash
cd local-setup/minikube
./up.sh argocd
```
Now change something in `deploy/helm/taskboard/values-local.yaml` (e.g. `replicas: 2`), commit and push:
Argo CD notices the changed file (within ~3 minutes) and redeploys only what changed.
