#!/usr/bin/env bash
set -euo pipefail

# Запускать из активного административного контекста Minikube.
CONTEXT="${CONTEXT:-$(kubectl config current-context)}"
CLUSTER="$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}')"
CERT_DIR="${CERT_DIR:-./certs}"
mkdir -p "$CERT_DIR"

create_user() {
  local user_name="$1"
  local group_name="$2"
  local csr_name="pd-${user_name}"
  local key_file="$CERT_DIR/${user_name}-key.pem"
  local csr_file="$CERT_DIR/${user_name}.csr"
  local cert_file="$CERT_DIR/${user_name}.crt"
  local request

  openssl genrsa -out "$key_file" 2048
  openssl req -new -key "$key_file" -out "$csr_file" -subj "/CN=${user_name}/O=${group_name}"
  request="$(base64 < "$csr_file" | tr -d '\n')"

  kubectl delete certificatesigningrequest "$csr_name" --ignore-not-found=true
  cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${csr_name}
spec:
  request: ${request}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000
  usages:
    - client auth
EOF
  kubectl certificate approve "$csr_name"
  kubectl get certificatesigningrequest "$csr_name" -o jsonpath='{.status.certificate}' | base64 --decode > "$cert_file"

  kubectl config set-credentials "$user_name" \
    --client-key="$key_file" \
    --client-certificate="$cert_file" \
    --embed-certs=true
  kubectl config set-context "${user_name}@${CONTEXT}" \
    --cluster="$CLUSTER" \
    --user="$user_name"
}

create_user operations-viewer pd:operations-viewers
create_user sales-developer pd:sales-developers
create_user tenant-developer pd:tenant-developers
create_user platform-operator pd:platform-operators
create_user security-auditor pd:security-auditors
create_user platform-admin pd:platform-admins

chmod 600 "$CERT_DIR"/*-key.pem
echo "Созданы kubeconfig contexts для демонстрационных пользователей в контексте ${CONTEXT}."
