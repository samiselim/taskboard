# 04 - Final Project: TaskBoard on AWS (Instructor Notes)

This folder contains the **student brief** and a **complete reference implementation** of the final project.

## What to Give the Students

| Give | Why |
|------|-----|
| [`PROJECT.md`](PROJECT.md) + `images/` | The brief (with its two architecture diagrams): **Part A, Local Setup** (Dockerfiles, Compose, local scans, Helm chart, minikube, Argo CD), then **Part B, Deploy to AWS EKS** |
| `app/` **source code only** | Students write the Dockerfiles themselves (Phase A1), so remove `Dockerfile`, `.dockerignore` and `nginx.conf.template` first |

Create the student starter package:
```bash
rsync -a --exclude 'Dockerfile' --exclude '.dockerignore' --exclude 'nginx.conf.template' \
  app images PROJECT.md ../taskboard-student-starter/
```

Keep the rest as the **reference solution** (or release it after the deadline):

| Folder | Contents |
|--------|----------|
| `app/*/Dockerfile`, `app/frontend/nginx.conf.template` | Phase A1: backend image (non-root, pip removed) and frontend image (multi-stage, unprivileged nginx with `/api` proxy) |
| [`local-setup/`](local-setup/) | Phases A2–A6: Docker Compose (+ SonarQube profile), README, minikube scripts (`up.sh` / `up.sh argocd` / `down.sh`) |
| [`infra/bootstrap`](infra/bootstrap) | State bucket, GitHub OIDC provider, Terraform CI role (applied once from a laptop) |
| [`infra/modules`](infra/modules) | `network`, `eks`, `ecr`, `backend-alb`, `static-site`, `github-oidc-role`, `platform` |
| [`infra/environments/prod`](infra/environments/prod) | Wires the modules; remote state with S3 native locking |
| [`deploy/helm/taskboard`](deploy/helm/taskboard) | Helm chart: backend Deployment, PostgreSQL StatefulSet, Secret / ExternalSecret, TargetGroupBinding, `helm test`; `values-local.yaml` (minikube) and `values-prod.yaml` (EKS) |
| [`gitops/`](gitops) | `install-argocd.sh` (Argo CD Helm chart + one Application) and the two Applications `taskboard-local.yaml` / `taskboard-prod.yaml` |
| [`.github/actions`](.github/actions) | Composite actions `pre-build-scan` and `post-build-scan` |
| [`.github/workflows`](.github/workflows) | `infra`, `backend`, `frontend`, `helm`, `release` |

> The students' repository root = the content of this folder (`.github/` must be at the root of the repo).

## How the Pieces Connect

```text
PR  ──► backend.yml / frontend.yml / helm.yml / infra.yml
          pre-build-scan (Gitleaks, TruffleHog, Trivy fs, SonarQube) ─► test/build ─► post-build-scan (Trivy image/fs + SBOM)
main ─► backend image sha-<commit> pushed to ECR      infra.yml: plan ─► (approval) ─► apply
Release vX.Y.Z ─► release.yml
          ├─ ECR: add tag vX.Y.Z to the sha-<commit> image (no rebuild)
          ├─ PR: deploy/helm/taskboard/values-prod.yaml backend.image.tag = vX.Y.Z ─► merge ─► Argo CD sync
          └─ (approval, environment "production") frontend build ─► S3 ─► CloudFront invalidation
```

## Verification Status of the Reference Solution
Nothing was applied to AWS. What was verified locally:

| Part | How it was verified |
|------|---------------------|
| Backend | `flake8` clean; `pytest`: 9 tests pass, 93% coverage |
| Frontend | `npm run lint`, `npm run typecheck` and `npm run build` (static export) pass in `node:22-alpine` |
| Docker Compose | `docker compose up --build`: all services healthy; through the frontend's `/api` proxy, tasks were created, completed, listed and validated (422 on empty title); data survives a backend restart |
| Helm chart on a local cluster | Tested on kind before the switch to minikube (same chart, same commands apart from cluster creation and image loading): chart installed, `helm test` passes; tasks survive deleting `taskboard-postgres-0`; pods run as UID 70 / 10001 with a read-only root filesystem |
| Helm chart (EKS mode) | `helm lint` + `helm template` with `values-prod.yaml` (ExternalSecret, SecretStore, TargetGroupBinding rendered) |
| Terraform | `terraform fmt -check` + `terraform validate` (bootstrap + prod) with the real registry modules (EKS v21, VPC v6, Pod Identity v2) |
| Workflows + composite actions | `actionlint` + `shellcheck` clean |
| Security scans | Trivy 0.75.0: 0 HIGH/CRITICAL on `app/`, `deploy/`, `infra/` (3 accepted risks in [`.trivyignore`](.trivyignore)); backend image 0 HIGH/CRITICAL when built with `--pull` |

Bugs found and fixed during these tests (useful teaching moments):
- `pg_isready` in the init container needs `-U`: UID 10001 has no user name, so without it pg_isready never tries to connect.
- A stale cached `python:3.13-slim` brought 3 CRITICAL OS vulnerabilities, so builds use `--pull`. pip is removed from the runtime image (its bundled libraries were flagged).
- Trivy flagged the PostgreSQL StatefulSet (root, writable root filesystem), which is now hardened.

**Not verified (needs a real AWS account + GitHub repository):** `terraform apply`, the EKS add-ons, External Secrets with Pod Identity, the TargetGroupBinding, CloudFront routing, Argo CD syncing from GitHub, and the GitHub Actions runs themselves. Do one full dry run on your own account before the course.

## Pinned Versions (Checked October 2026)
| Component | Version |
|-----------|---------|
| Terraform / AWS provider / Helm provider | 1.16.5 / ~> 6.0 (6.68) / ~> 3.0 (3.3) |
| Modules: EKS / VPC / EKS Pod Identity | ~> 21.0 / ~> 6.7 / ~> 2.0 |
| Kubernetes (EKS) | 1.34 (variable `kubernetes_version`) |
| Helm charts: Argo CD / AWS LB Controller / External Secrets | 10.10.3 / 3.6.0 / 2.12.0 |
| Scanner actions: trivy-action / gitleaks-action / trufflehog / sonarqube-scan-action | v0.36.0 (SHA, Trivy 0.75.0) / v3 / v3.99.2 / v8 |
| Next.js / React / FastAPI / PostgreSQL | 16.4.0 / 19.3.0 / 0.143.0 / 17 |

> The composite actions use the official actions (`gitleaks/gitleaks-action@v3`, `trufflesecurity/trufflehog@v3.99.2`, `SonarSource/sonarqube-scan-action@v8`). `aquasecurity/trivy-action` is pinned to the **commit SHA** of v0.36.0 (released after its tags were hijacked in March 2026) and runs Trivy v0.75.0.
