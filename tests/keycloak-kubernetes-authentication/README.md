# OIDC User Access Test (Stack4Things)

This short guide shows how to test Kubernetes access using an OIDC user by
switching contexts and verifying RBAC restrictions.

---
## Prerequisites

The commands in Step 1 must be executed from a directory such that the following file exists relative to the current working directory:
```bash
../../resources/k3d-cluster/certificate/certs/ca.crt
```
This file contains the Certificate Authority (CA) used to sign the TLS certificate of Keycloak.
If your directory layout is different, adjust the --cacert path accordingly.

## 1. Get an OIDC Token from Keycloak

```bash
TOKEN=$(curl -s --cacert ../../resources/k3d-cluster/certificate/certs/ca.crt \
  -X POST "https://host.k3d.internal:8443/realms/stack4things/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=kubernetes" \
  -d "username=testuser" \
  -d "password=testpassword" | jq -r .access_token)
```

## 2. Add the OIDC User Context
```bash
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
SERVER=${API_SERVER/0.0.0.0/127.0.0.1}
CA_DATA=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
```

```bash
cat > /tmp/kc-oidc.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- name: k3d-stack4things-cluster
  cluster:
    server: ${SERVER}
    certificate-authority-data: ${CA_DATA}
users:
- name: testuser-oidc
  user:
    token: ${TOKEN}
contexts:
- name: testuser
  context:
    cluster: k3d-stack4things-cluster
    user: testuser-oidc
current-context: testuser
EOF
```

```bash
kubectl config view --kubeconfig ~/.kube/config:/tmp/kc-oidc.yaml --flatten > /tmp/config.merged
mv /tmp/config.merged ~/.kube/config
```

## 3. Switch Context and Test Access
```bash
kubectl config use-context testuser
kubectl auth whoami
``` 
```bash
kubectl get nodes
kubectl get pods
```

Expected result: 

```bash
Error from server (Forbidden): pods is forbidden: User "https://host.k3d.internal:8443/realms/stack4things#testuser" cannot list resource "pods" in API group "" in the namespace "default"
```
## 4. Switch Back to Admin
```bash
kubectl config use-context k3d-stack4things-cluster
```
 
