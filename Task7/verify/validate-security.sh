#!/usr/bin/env bash
set -euo pipefail

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! kubectl get crd constrainttemplates.templates.gatekeeper.sh >/dev/null 2>&1; then
  echo "Gatekeeper is not installed. Install it before running this validation." >&2
  exit 1
fi

kubectl apply -f "$TASK_DIR/01-create-namespace.yaml"
kubectl create namespace gatekeeper-validation --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$TASK_DIR/gatekeeper/constraint-templates"

wait_for_constraint_crd() {
  local crd_name="$1"
  local attempt
  for attempt in {1..30}; do
    if kubectl get "crd/${crd_name}" >/dev/null 2>&1; then
      kubectl wait --for=condition=Established "crd/${crd_name}" --timeout=60s
      return
    fi
    sleep 2
  done
  echo "Gatekeeper did not create CRD: ${crd_name}" >&2
  exit 1
}

wait_for_constraint_crd k8sdisallowprivileged.constraints.gatekeeper.sh
wait_for_constraint_crd k8sdisallowhostpath.constraints.gatekeeper.sh
wait_for_constraint_crd k8srequiredcontainersecurity.constraints.gatekeeper.sh
kubectl apply -f "$TASK_DIR/gatekeeper/constraints"

"$TASK_DIR/verify/verify-admission.sh"

# `gatekeeper-validation` has no PodSecurity labels, so these rejections prove Gatekeeper enforcement.
for manifest in "$TASK_DIR"/insecure-manifests/*.yaml; do
  if sed 's/namespace: audit-zone/namespace: gatekeeper-validation/' "$manifest" \
      | kubectl apply --dry-run=server -f - >/dev/null 2>&1; then
    echo "ERROR: Gatekeeper accepted insecure manifest: $manifest" >&2
    exit 1
  fi
  echo "Gatekeeper rejected insecure manifest as expected: $(basename "$manifest")"
done

cat <<'EOF' | kubectl apply --dry-run=server -f - >/dev/null 2>&1 && {
apiVersion: v1
kind: Pod
metadata:
  name: writable-rootfs-test
  namespace: gatekeeper-validation
spec:
  containers:
    - name: app
      image: nginxinc/nginx-unprivileged:stable-alpine
      securityContext:
        runAsNonRoot: true
        readOnlyRootFilesystem: false
EOF
  echo "ERROR: Gatekeeper accepted writable root filesystem." >&2
  exit 1
} || echo "Gatekeeper rejected writable root filesystem as expected."

echo "PodSecurity Admission and Gatekeeper validations completed."
