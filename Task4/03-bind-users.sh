#!/usr/bin/env bash
set -euo pipefail

kubectl create clusterrolebinding pd-operations-viewers \
  --clusterrole=pd-cluster-viewer \
  --group=pd:operations-viewers \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create clusterrolebinding pd-platform-operators \
  --clusterrole=pd-platform-operator \
  --group=pd:platform-operators \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create clusterrolebinding pd-security-auditors \
  --clusterrole=pd-security-auditor \
  --group=pd:security-auditors \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create clusterrolebinding pd-platform-admins \
  --clusterrole=cluster-admin \
  --group=pd:platform-admins \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create rolebinding pd-sales-developers \
  --namespace=sales \
  --clusterrole=pd-domain-deployer \
  --group=pd:sales-developers \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create rolebinding pd-tenant-developers \
  --namespace=tenant-services \
  --clusterrole=pd-domain-deployer \
  --group=pd:tenant-developers \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Группы связаны с ролями. Доступ cluster-admin предназначен только для break-glass операций."
