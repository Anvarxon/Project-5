#!/usr/bin/env bash
set -euo pipefail

for namespace in sales tenant-services finance data; do
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
done

cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd-cluster-viewer
rules:
  - apiGroups: [""]
    resources: ["namespaces", "pods", "pods/log", "services", "endpoints", "configmaps", "events", "persistentvolumeclaims"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps", "batch", "autoscaling", "networking.k8s.io"]
    resources: ["deployments", "replicasets", "statefulsets", "daemonsets", "jobs", "cronjobs", "horizontalpodautoscalers", "ingresses", "networkpolicies"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd-domain-deployer
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log", "services", "endpoints", "configmaps", "events", "persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["apps", "batch", "autoscaling"]
    resources: ["deployments", "replicasets", "statefulsets", "jobs", "cronjobs", "horizontalpodautoscalers"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses", "networkpolicies"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd-platform-operator
rules:
  - apiGroups: [""]
    resources: ["namespaces", "pods", "pods/log", "services", "endpoints", "configmaps", "events", "persistentvolumeclaims", "persistentvolumes", "resourcequotas", "limitranges"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["apps", "batch", "autoscaling", "networking.k8s.io", "storage.k8s.io"]
    resources: ["*"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd-security-auditor
rules:
  - apiGroups: [""]
    resources: ["namespaces", "pods", "pods/log", "services", "configmaps", "events", "secrets", "serviceaccounts"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps", "batch", "networking.k8s.io", "rbac.authorization.k8s.io"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
EOF

echo "Роли и доменные namespace созданы."
