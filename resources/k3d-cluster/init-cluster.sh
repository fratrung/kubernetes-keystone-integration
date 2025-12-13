#!/usr/bin/env bash
set -euo pipefail

CLUSTER="stack4things-cluster"

k3d cluster delete "$CLUSTER" >/dev/null 2>&1 || true
k3d cluster create --config s4t-clustrt-config.yaml
kubectl config use-context "k3d-$CLUSTER"

kubectl run kc-curl --image=curlimages/curl:8.5.0 -it --rm --restart=Never -- \
  curl -fsS "http://localhost:8081/realms/stack4things/.well-known/openid-configuration" >/dev/null

echo "OK: kube-apiserver potrà validare JWT con issuer http://localhost:8081"
