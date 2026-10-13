#!/usr/bin/env bash
# Delete the "taskboard" minikube profile (and everything in it, including the database volume).
# Use "minikube stop -p taskboard" instead to keep it for later.
set -euo pipefail
minikube delete -p taskboard
