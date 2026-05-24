#!/usr/bin/env bash
set -euo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$TASK_DIR/01-create-namespace.yaml"

for manifest in "$TASK_DIR"/insecure-manifests/*.yaml; do
  if kubectl apply --dry-run=server -f "$manifest" >/dev/null 2>&1; then
    echo "ERROR: PodSecurity accepted insecure manifest: $manifest" >&2
    exit 1
  fi
  echo "PodSecurity rejected insecure manifest as expected: $(basename "$manifest")"
done

for manifest in "$TASK_DIR"/secure-manifests/*.yaml; do
  kubectl apply --dry-run=server -f "$manifest" >/dev/null
  echo "PodSecurity accepted secure manifest: $(basename "$manifest")"
done
